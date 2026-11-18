// Componentes das telas de conta (Login, Cadastro, Recuperar senha e Perfil).
// As cores vêm do tema do app (lib/theme/app_theme.dart) por
// Theme.of(context).colorScheme, que já troca sozinho no modo escuro.
import 'package:flutter/material.dart';

import 'ajuda.dart';

void showMsg(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

/// Barra do topo no mesmo estilo das outras abas (Início, Em construção).
/// Em telas abertas por cima (Cadastro, Recuperar senha) aparece a seta de
/// voltar sozinha. [ajuda] é o texto do botão "i" (ver TextosAjuda).
AppBar barraConta(BuildContext context, String titulo,
        {required String ajuda}) =>
    AppBar(
      title: Text(titulo),
      centerTitle: false,
      toolbarHeight: 72,
      titleSpacing: 20,
      titleTextStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      actions: [
        BotaoAjuda(texto: ajuda),
        const SizedBox(width: 12),
      ],
    );

class AppField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  const AppField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboard,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              color: cores.primary, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      // Bordas, fundo e espaçamento vêm do inputDecorationTheme do app.
      TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: cores.onSurfaceVariant),
        ),
      ),
      const SizedBox(height: 14),
    ]);
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryButton(
      {super.key, required this.text, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary))
            : Text(text),
      );
}

class OutlineButtonX extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const OutlineButtonX({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) =>
      OutlinedButton(onPressed: onPressed, child: Text(text));
}

String? validateEmail(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Informe o e-mail';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'E-mail inválido';
  return null;
}

String? validatePassword(String? v) =>
    (v ?? '').length < 8 ? 'Mínimo 8 caracteres' : null;
