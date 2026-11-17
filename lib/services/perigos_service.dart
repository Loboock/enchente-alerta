import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../models/models.dart';
import '../models/perigo.dart';
import 'auth_service.dart';

/// Erro já traduzido para mostrar na tela.
class PerigoException implements Exception {
  PerigoException(this.mensagem);
  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Alagamentos em tempo real: avisos da comunidade (`ocorrencias`) e áreas
/// da Defesa Civil (`areasRisco`), juntos em [perigos].
///
/// Também é por aqui que o usuário reporta, confirma ("ainda está aí") ou
/// nega ("não está mais aqui") um aviso, como no Waze.
class PerigosService {
  PerigosService();

  /// Trocável nos testes por uma versão falsa.
  static PerigosService instance = PerigosService();

  /// Lista atual, atualizada sozinha quando o Firestore muda.
  final perigos = ValueNotifier<List<Perigo>>(const []);

  var _ocorrencias = <Ocorrencia>[];
  var _areas = <AreaRisco>[];
  final _assinaturas = <StreamSubscription<Object?>>[];
  Timer? _relogio;
  bool _iniciado = false;

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      // Firebase não inicializado (ex.: flutter test).
      return null;
    }
  }

  /// Começa a ouvir o Firestore (chamar quantas vezes quiser).
  void iniciar() {
    if (_iniciado) return;
    _iniciado = true;
    final db = _db;
    if (db == null) return;

    // Só pelo status: filtrar também por `expiraEm` exigiria um índice
    // composto. As expiradas são descartadas aqui no app.
    _assinaturas.add(
      db
          .collection('ocorrencias')
          .where('status', isEqualTo: StatusOcorrencia.ativa.codigo)
          .snapshots()
          .listen(
        (snap) {
          _ocorrencias = [
            for (final doc in snap.docs)
              ?_ler(() => Ocorrencia.fromFirestore(doc)),
          ];
          _publicar();
        },
        onError: (Object e) => debugPrint('ocorrencias: $e'),
      ),
    );
    _assinaturas.add(
      db.collection('areasRisco').snapshots().listen(
        (snap) {
          _areas = [
            for (final doc in snap.docs)
              ?_ler(() => AreaRisco.fromFirestore(doc)),
          ];
          _publicar();
        },
        onError: (Object e) => debugPrint('areasRisco: $e'),
      ),
    );
    // Avisos expiram com o tempo, mesmo sem mudança no banco.
    _relogio = Timer.periodic(const Duration(minutes: 1), (_) => _publicar());
  }

  /// Um documento com dado inválido não pode derrubar o mapa inteiro.
  T? _ler<T>(T Function() ler) {
    try {
      return ler();
    } catch (e) {
      debugPrint('Documento ignorado: $e');
      return null;
    }
  }

  void _publicar() {
    final agora = DateTime.now();
    perigos.value = [
      for (final a in _areas)
        if (a.poligono.length >= 3) Perigo.daArea(a),
      for (final o in _ocorrencias)
        if (o.estaAtiva(agora)) Perigo.daOcorrencia(o, agora: agora),
    ];
  }

  String _uidObrigatorio() {
    final uid = AuthService.instance.user?.uid;
    if (uid == null) {
      throw PerigoException('Entre na sua conta para enviar avisos.');
    }
    return uid;
  }

  FirebaseFirestore _dbObrigatorio() {
    final db = _db;
    if (db == null) throw PerigoException('Sem conexão com o servidor.');
    return db;
  }

  /// Cria um aviso no local [local]. Quem reporta já conta como a primeira
  /// confirmação; a rota só desvia depois que mais alguém confirmar.
  Future<void> reportar({
    required TipoOcorrencia tipo,
    required Gravidade gravidade,
    required LatLng local,
    required String endereco,
    int nivelAguaCm = 0,
    String? descricao,
  }) async {
    final uid = _uidObrigatorio();
    final db = _dbObrigatorio();
    final agora = DateTime.now();
    final ref = db.collection('ocorrencias').doc();

    final ocorrencia = Ocorrencia(
      id: ref.id,
      tipo: tipo,
      gravidade: gravidade,
      endereco: endereco,
      localizacao: local,
      nivelAguaCm: nivelAguaCm,
      descricao: (descricao?.trim().isEmpty ?? true) ? null : descricao!.trim(),
      criadaEm: agora,
      expiraEm: agora.add(Config.duracaoOcorrencia),
    );

    final lote = db.batch()
      ..set(ref, ocorrencia.toFirestore())
      // Autor separado para manter o anonimato (RNF07).
      ..set(db.collection('autoresOcorrencias').doc(ref.id), {
        'autorId': uid,
      })
      // Marca que o autor já "confirmou", para não contar duas vezes.
      ..set(ref.collection('confirmacoes').doc(uid), {
        'criadaEm': FieldValue.serverTimestamp(),
      });
    await _executar(lote.commit);
  }

  /// "Ainda está aí": soma uma confirmação (uma por pessoa) e renova o
  /// prazo do aviso.
  Future<void> confirmar(Ocorrencia ocorrencia) async {
    final uid = _uidObrigatorio();
    final db = _dbObrigatorio();
    final ref = db.collection('ocorrencias').doc(ocorrencia.id);
    final minha = ref.collection('confirmacoes').doc(uid);

    // Checa antes também: o erro lançado dentro da transação pode chegar
    // embrulhado pelo Firebase, e aqui a mensagem sai certa.
    await _executar(() async {
      if ((await minha.get()).exists) {
        throw PerigoException('Você já confirmou este aviso.');
      }
      return null;
    });

    await _executar(
      () => db.runTransaction((tx) async {
        if ((await tx.get(minha)).exists) {
          throw PerigoException('Você já confirmou este aviso.');
        }
        tx.set(minha, {'criadaEm': FieldValue.serverTimestamp()});
        tx.update(ref, {
          'confirmacoes': FieldValue.increment(1),
          'expiraEm': Timestamp.fromDate(
            DateTime.now().add(Config.duracaoOcorrencia),
          ),
        });
        return null;
      }),
    );
  }

  /// "Não está mais aqui": vira uma denúncia para a Defesa Civil revisar.
  Future<void> negar(Ocorrencia ocorrencia) =>
      denunciar(ocorrencia, motivo: MotivoDenuncia.aguaBaixou);

  /// Tela "Reportar aviso": denúncia com motivo e detalhes opcionais.
  ///
  /// A denúncia fica em `denuncias/{uid}`, então cada pessoa denuncia um
  /// aviso uma vez só (a regra do Firestore recusa a segunda).
  Future<void> denunciar(
    Ocorrencia ocorrencia, {
    required MotivoDenuncia motivo,
    String? detalhes,
  }) async {
    final uid = _uidObrigatorio();
    final db = _dbObrigatorio();
    final texto = detalhes?.trim();
    final denuncia = Denuncia(
      id: uid,
      autorId: uid,
      motivo: motivo,
      detalhes: (texto == null || texto.isEmpty) ? null : texto,
      criadaEm: DateTime.now(),
    );
    try {
      await _executar(
        () => db
            .collection('ocorrencias')
            .doc(ocorrencia.id)
            .collection('denuncias')
            .doc(uid)
            .set(denuncia.toFirestore()),
      );
    } on PerigoException catch (e) {
      // A única recusa possível para quem está logado é a denúncia repetida.
      if (e.mensagem.startsWith('Sem permissão')) {
        throw PerigoException('Você já reportou este aviso.');
      }
      rethrow;
    }
  }

  /// Exclui um aviso do próprio usuário (ou qualquer um, para a Defesa
  /// Civil), junto com o registro do autor.
  Future<void> excluir(Ocorrencia ocorrencia) async {
    _uidObrigatorio();
    final db = _dbObrigatorio();
    final lote = db.batch()
      ..delete(db.collection('ocorrencias').doc(ocorrencia.id))
      ..delete(db.collection('autoresOcorrencias').doc(ocorrencia.id));
    await _executar(lote.commit);
  }

  /// Ids dos avisos criados por [uid], para mostrar o botão "Excluir" só
  /// nos avisos da própria pessoa. O autor continua fora do documento
  /// público da ocorrência (RNF07): só ele consegue ler esta consulta.
  Stream<Set<String>> idsDoAutor(String uid) {
    final db = _db;
    if (db == null) return Stream.value(const {});
    return db
        .collection('autoresOcorrencias')
        .where('autorId', isEqualTo: uid)
        .snapshots()
        .map((snap) => {for (final doc in snap.docs) doc.id})
        .handleError((Object e) => debugPrint('autoresOcorrencias: $e'));
  }

  Future<void> _executar(Future<Object?> Function() acao) async {
    try {
      await acao();
    } on PerigoException {
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw PerigoException('Sem permissão para enviar este aviso.');
      }
      throw PerigoException('Não foi possível enviar. Tente de novo.');
    } catch (_) {
      throw PerigoException('Não foi possível enviar. Tente de novo.');
    }
  }

  void parar() {
    for (final a in _assinaturas) {
      a.cancel();
    }
    _assinaturas.clear();
    _relogio?.cancel();
    _iniciado = false;
  }
}
