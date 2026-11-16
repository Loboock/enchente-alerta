import 'package:flutter/material.dart';

/// Aviso provisório para botões cuja função ainda não foi implementada.
void avisoEmBreve(BuildContext context, String recurso) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$recurso: em breve')));
}
