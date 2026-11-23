import 'package:flutter/material.dart';

import '../../services/erro_servico.dart';

/// Pergunta antes de uma ação que muda o que os moradores veem.
Future<bool> confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String botao,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(contexto, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(contexto, true),
          child: Text(botao),
        ),
      ],
    ),
  );
  return ok == true;
}

void mostrarMensagem(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));
}

/// Executa a gravação e mostra [sucesso] ou o erro traduzido.
Future<bool> executarComAviso(
  BuildContext context,
  Future<void> Function() acao, {
  required String sucesso,
}) async {
  try {
    await acao();
    if (context.mounted) mostrarMensagem(context, sucesso);
    return true;
  } on ServicoException catch (e) {
    if (context.mounted) mostrarMensagem(context, e.mensagem);
    return false;
  }
}
