import 'package:flutter/material.dart';

import '../navegacao.dart';
import '../services/auth_service.dart';

/// Ações que gravam no banco (reportar, confirmar) precisam de conta.
/// Sem login, mostra um aviso com o atalho para a aba Perfil.
bool exigirLogin(BuildContext context, {String acao = 'enviar avisos'}) {
  if (AuthService.instance.user != null) return true;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Entre na sua conta para $acao.'),
        action: SnackBarAction(
          label: 'Entrar',
          onPressed: () => irParaAba(context, 3),
        ),
      ),
    );
  return false;
}
