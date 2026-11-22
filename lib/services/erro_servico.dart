import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Erro já traduzido para mostrar na tela (abrigos, alertas, denúncias).
class ServicoException implements Exception {
  ServicoException(this.mensagem);
  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Firestore, ou null quando o Firebase não foi inicializado (flutter test).
FirebaseFirestore? firestoreOuNull() {
  try {
    return FirebaseFirestore.instance;
  } catch (_) {
    return null;
  }
}

FirebaseFirestore firestoreObrigatorio() =>
    firestoreOuNull() ?? (throw ServicoException('Sem conexão com o servidor.'));

/// Executa uma gravação e traduz os erros do Firebase.
///
/// Sem internet, o Firestore guarda a gravação no aparelho e só termina o
/// envio quando a conexão volta. Por isso há um limite de espera: depois
/// dele a tela avisa que a alteração vai ser enviada assim que possível.
Future<void> gravarNoFirestore(
  Future<void> Function() acao, {
  Duration limite = const Duration(seconds: 12),
}) async {
  try {
    await acao().timeout(limite);
  } on TimeoutException {
    throw ServicoException(
        'Sem conexão. A alteração fica salva no aparelho e será enviada '
        'quando a internet voltar.');
  } on ServicoException {
    rethrow;
  } on FirebaseException catch (e) {
    throw ServicoException(switch (e.code) {
      'permission-denied' =>
        'Sem permissão. Só a Defesa Civil pode fazer esta alteração.',
      'unavailable' => 'Sem conexão com a internet. Tente de novo.',
      _ => 'Não foi possível salvar. Tente de novo.',
    });
  } catch (_) {
    throw ServicoException('Não foi possível salvar. Tente de novo.');
  }
}
