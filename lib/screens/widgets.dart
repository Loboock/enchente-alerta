import 'package:flutter/material.dart';
import 'screens/placeholder_screen.dart';
import 'services/auth_service.dart';
import 'theme.dart';

void showMsg(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

class AppShell extends StatelessWidget {
  final String title;
  final Widget child;
  final int currentIndex;
  const AppShell(
      {super.key, required this.title, required this.child, this.currentIndex = 3});

  static const _items = [
    (Icons.home_outlined, 'Início'),
    (Icons.notifications_none, 'Avisos'),
    (Icons.schedule, 'Histórico'),
    (Icons.person_outline, 'Perfil'),
    (Icons.menu_book_outlined, 'Guia'),
  ];

  void _onTap(BuildContext c, int i) {
    if (AuthService.instance.user == null) {
      showMsg(c, 'Faça login para acessar.');
      return;
    }
    if (i == currentIndex) return;
    final nav = Navigator.of(c);
    if (i == 3) {
      nav.popUntil((r) => r.isFirst);
    } else {
      nav.push(MaterialPageRoute(
          builder: (_) => PlaceholderScreen(title: _items[i].$2, index: i)));
    }
  }

  void _help(BuildContext c) => showDialog(
        context: c,
        builder: (_) => AlertDialog(
          title: const Text('Ajuda'),
          content: const Text(
              'O Enchente Alerta envia avisos de alagamento da sua região em tempo real.\n\n'
              'Problemas com acesso? Use "Esqueceu a senha?" na tela de login.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar'))
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        Container(
          color: kBlue,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                InkWell(
                  onTap: () => _help(context),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.question_mark, color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Expanded(child: child),
        Container(
          color: kBlue,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                for (int i = 0; i < _items.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => _onTap(context, i),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_items[i].$1,
                            size: 22, color: i == currentIndex ? kOrange : Colors.white70),
                        const SizedBox(height: 2),
                        Text(_items[i].$2,
                            style: TextStyle(
                                fontSize: 10,
                                color: i == currentIndex ? kOrange : Colors.white70)),
                      ]),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

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
    OutlineInputBorder b([Color c = kBorder]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(color: kLabel, fontSize: 11, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: validator,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: kGrey, fontSize: 12),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: b(),
          enabledBorder: b(),
          focusedBorder: b(kBlue),
          errorBorder: b(Colors.red),
          focusedErrorBorder: b(Colors.red),
          errorStyle: const TextStyle(fontSize: 10),
        ),
      ),
      const SizedBox(height: 10),
    ]);
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryButton({super.key, required this.text, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              disabledBackgroundColor: kBlue.withAlpha(150),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      );
}

class OutlineButtonX extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const OutlineButtonX({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kBlue,
              side: const BorderSide(color: kBlue, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      );
}

String? validateEmail(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Informe o e-mail';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'E-mail inválido';
  return null;
}

String? validatePassword(String? v) =>
    (v ?? '').length < 8 ? 'Mínimo 8 caracteres' : null;
