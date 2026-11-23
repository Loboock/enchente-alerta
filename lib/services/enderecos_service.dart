import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'auth_service.dart';
import 'erro_servico.dart';

/// Endereços do usuário (`usuarios/{uid}/enderecos`), com um marcado como
/// padrão: a casa da pessoa, usada para filtrar os alertas da região
/// (CRUD de Preferências de localização, RF08).
///
/// Segue a conta logada sozinho: ao entrar, carrega; ao sair, limpa.
class EnderecosService {
  EnderecosService();

  /// Trocável nos testes por uma versão falsa.
  static EnderecosService instance = EnderecosService();

  /// Endereços da conta, com o padrão primeiro.
  final enderecos = ValueNotifier<List<Endereco>>(const []);

  Endereco? get padrao {
    for (final e in enderecos.value) {
      if (e.padrao) return e;
    }
    return null;
  }

  StreamSubscription<Object?>? _assinatura;
  String? _uid;
  bool _iniciado = false;

  void iniciar() {
    if (_iniciado) return;
    _iniciado = true;
    AuthService.instance.addListener(_aoMudarConta);
    _aoMudarConta();
  }

  void _aoMudarConta() {
    final uid = AuthService.instance.user?.uid;
    if (uid == _uid) return;
    _uid = uid;
    _assinatura?.cancel();
    _assinatura = null;
    enderecos.value = const [];
    final db = firestoreOuNull();
    if (uid == null || db == null) return;
    _assinatura = db
        .collection('usuarios')
        .doc(uid)
        .collection('enderecos')
        .snapshots()
        .listen(
      (snap) {
        final lista = <Endereco>[];
        for (final doc in snap.docs) {
          try {
            lista.add(Endereco.fromFirestore(doc));
          } catch (e) {
            debugPrint('Endereço ignorado: $e');
          }
        }
        lista.sort((a, b) {
          if (a.padrao != b.padrao) return a.padrao ? -1 : 1;
          return a.logradouro.compareTo(b.logradouro);
        });
        enderecos.value = lista;
      },
      onError: (Object e) => debugPrint('enderecos: $e'),
    );
  }

  String _uidObrigatorio() {
    final uid = AuthService.instance.user?.uid;
    if (uid == null) {
      throw ServicoException('Entre na sua conta para salvar endereços.');
    }
    return uid;
  }

  /// Cadastra (id vazio) ou altera. Se ficar como padrão, desmarca os
  /// outros na mesma gravação. O primeiro endereço já vira o padrão.
  Future<void> salvar(Endereco e) async {
    final uid = _uidObrigatorio();
    final db = firestoreObrigatorio();
    final col = db.collection('usuarios').doc(uid).collection('enderecos');
    final ref = e.id.isEmpty ? col.doc() : col.doc(e.id);
    final outros = enderecos.value.where((x) => x.id != ref.id).toList();
    final padrao = e.padrao || outros.isEmpty;
    final novo = Endereco(
      id: ref.id,
      logradouro: e.logradouro,
      bairro: e.bairro,
      cidade: e.cidade,
      localizacao: e.localizacao,
      padrao: padrao,
    );
    final lote = db.batch()..set(ref, novo.toFirestore());
    if (padrao) {
      for (final o in outros.where((o) => o.padrao)) {
        lote.update(col.doc(o.id), {'padrao': false});
      }
    }
    await gravarNoFirestore(lote.commit);
  }

  Future<void> definirPadrao(Endereco e) => salvar(_comPadrao(e, true));

  /// Exclui. Se era o padrão, o próximo da lista vira o padrão.
  Future<void> excluir(Endereco e) async {
    final uid = _uidObrigatorio();
    final db = firestoreObrigatorio();
    final col = db.collection('usuarios').doc(uid).collection('enderecos');
    final lote = db.batch()..delete(col.doc(e.id));
    if (e.padrao) {
      final proximo = enderecos.value.where((x) => x.id != e.id).firstOrNull;
      if (proximo != null) lote.update(col.doc(proximo.id), {'padrao': true});
    }
    await gravarNoFirestore(lote.commit);
  }

  static Endereco _comPadrao(Endereco e, bool padrao) => Endereco(
        id: e.id,
        logradouro: e.logradouro,
        bairro: e.bairro,
        cidade: e.cidade,
        localizacao: e.localizacao,
        padrao: padrao,
      );
}
