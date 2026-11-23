import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';
import 'alertas_regiao.dart';
import 'alertas_service.dart';
import 'auth_service.dart';
import 'enderecos_service.dart';
import 'erro_servico.dart';

/// Notificações do usuário (`usuarios/{uid}/notificacoes`): cada alerta da
/// Defesa Civil que chegou para a pessoa, com lida / não lida.
///
/// Sem Cloud Functions (plano Spark), quem cria a notificação é o próprio
/// app de quem recebe: quando aparece um alerta ativo que vale para a
/// região da pessoa e ela deixou os alertas ligados, o app grava a
/// notificação com o id do alerta (assim não repete).
class NotificacoesService {
  NotificacoesService();

  /// Trocável nos testes por uma versão falsa.
  static NotificacoesService instance = NotificacoesService();

  /// Da mais recente para a mais antiga.
  final notificacoes = ValueNotifier<List<Notificacao>>(const []);

  int get naoLidas => notificacoes.value.where((n) => !n.lida).length;

  StreamSubscription<Object?>? _assinatura;
  String? _uid;
  bool _carregou = false;
  bool _iniciado = false;
  final _gravando = <String>{};

  /// Alertas cujas notificações a pessoa excluiu: não voltam enquanto o
  /// alerta continuar ativo. Guardado num arquivo do aparelho.
  final _excluidas = <String>{};
  File? _arquivoExcluidas;

  void iniciar() {
    if (_iniciado) return;
    _iniciado = true;
    AuthService.instance.addListener(_aoMudarConta);
    AlertasService.instance.alertas.addListener(_registrarNovas);
    EnderecosService.instance.enderecos.addListener(_registrarNovas);
    _aoMudarConta();
    _carregarExcluidas();
  }

  Future<void> _carregarExcluidas() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final arq = File('${dir.path}/notificacoes_excluidas.txt');
      _arquivoExcluidas = arq;
      if (await arq.exists()) {
        _excluidas.addAll(
            (await arq.readAsLines()).where((l) => l.trim().isNotEmpty));
      }
    } catch (_) {
      // Sem a pasta (ex.: testes), vale só enquanto o app está aberto.
    }
  }

  void _aoMudarConta() {
    final uid = AuthService.instance.user?.uid;
    if (uid != _uid) {
      _uid = uid;
      _carregou = false;
      _assinatura?.cancel();
      _assinatura = null;
      notificacoes.value = const [];
      final col = _colecao();
      if (col != null) {
        _assinatura = col.snapshots().listen(
          (snap) {
            final lista = <Notificacao>[];
            for (final doc in snap.docs) {
              try {
                lista.add(Notificacao.fromFirestore(doc));
              } catch (e) {
                debugPrint('Notificação ignorada: $e');
              }
            }
            lista.sort((a, b) => b.enviadaEm.compareTo(a.enviadaEm));
            notificacoes.value = lista;
            _carregou = true;
            _registrarNovas();
          },
          onError: (Object e) => debugPrint('notificacoes: $e'),
        );
      }
    }
    // A preferência (ligar alertas, raio) também muda pelo AuthService.
    _registrarNovas();
  }

  CollectionReference<Map<String, dynamic>>? _colecao() {
    final uid = _uid;
    final db = firestoreOuNull();
    if (uid == null || db == null) return null;
    return db.collection('usuarios').doc(uid).collection('notificacoes');
  }

  /// Grava a notificação dos alertas novos que valem para a pessoa.
  void _registrarNovas() {
    final col = _colecao();
    if (col == null || !_carregou) return;
    if (!AuthService.instance.notificacoesAtivas) return;
    final existentes = {for (final n in notificacoes.value) n.id};
    for (final alerta in alertasParaMim()) {
      if (existentes.contains(alerta.id) ||
          _excluidas.contains(alerta.id) ||
          !_gravando.add(alerta.id)) {
        continue;
      }
      final n = Notificacao(
        id: alerta.id,
        mensagem: _mensagem(alerta),
        alertaId: alerta.id,
        enviadaEm: DateTime.now(),
      );
      col.doc(alerta.id).set(n.toFirestore()).catchError((Object e) {
        debugPrint('Notificação não gravada: $e');
      }).whenComplete(() => _gravando.remove(alerta.id));
    }
  }

  static String _mensagem(Alerta a) {
    final texto = 'Defesa Civil · ${a.nivel.rotulo}: ${a.titulo}';
    return texto.length <= 300 ? texto : texto.substring(0, 300);
  }

  Future<void> marcarLida(Notificacao n) async {
    if (n.lida) return;
    final col = _colecao();
    if (col == null) return;
    await gravarNoFirestore(() => col.doc(n.id).update({'lida': true}));
  }

  Future<void> marcarTodasLidas() async {
    final col = _colecao();
    final db = firestoreOuNull();
    if (col == null || db == null) return;
    final lote = db.batch();
    for (final n in notificacoes.value.where((n) => !n.lida)) {
      lote.update(col.doc(n.id), {'lida': true});
    }
    await gravarNoFirestore(lote.commit);
  }

  Future<void> excluir(Notificacao n) async {
    final col = _colecao();
    if (col == null) return;
    if (_excluidas.add(n.id)) {
      try {
        await _arquivoExcluidas?.writeAsString('${n.id}\n',
            mode: FileMode.append);
      } catch (_) {}
    }
    await gravarNoFirestore(() => col.doc(n.id).delete());
  }
}
