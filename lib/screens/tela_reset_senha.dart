import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, this.email = ''});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _confirmReset() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.resetPassword(_email.text, _pass.text);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Senha redefinida'),
          content: const Text('Agora você já pode entrar com a nova senha.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showMsg(context, AuthService.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Recuperar senha',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Redefinir senha',
                style: TextStyle(color: kBlue, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Informe seu e-mail e crie uma nova senha de acesso.',
                style: TextStyle(color: kGrey, fontSize: 10)),
            const SizedBox(height: 14),
            AppField(
                label: 'E-mail',
                hint: 'voce@email.com',
                controller: _email,
                keyboard: TextInputType.emailAddress,
                validator: validateEmail),
            AppField(
                label: 'Nova senha',
                hint: 'Mínimo 8 caracteres',
                controller: _pass,
                obscure: true,
                validator: validatePassword),
            AppField(
                label: 'Confirmar senha',
                hint: 'Repita a senha',
                controller: _confirm,
                obscure: true,
                validator: (v) => v != _pass.text ? 'As senhas não coincidem' : null),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                  child: OutlineButtonX(
                      text: 'Voltar ao login', onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(
                  child: PrimaryButton(
                      text: 'Confirmar', onPressed: _confirmReset, loading: _loading)),
            ]),
          ]),
        ),
      ),
    );
  }
}
