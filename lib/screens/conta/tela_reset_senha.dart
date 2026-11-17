import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/widgets_conta.dart';

/// Recuperar senha: o Firebase envia um e-mail com o link para criar a nova
/// senha (a senha nova não é digitada no app).
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, this.email = ''});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.resetPassword(_email.text);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verifique seu e-mail'),
          content: Text(
              'Se existir uma conta com ${_email.text.trim()}, você vai receber '
              'um link para criar uma nova senha. Confira também a caixa de spam.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
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
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: barraConta(context, 'Recuperar senha'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Redefinir senha',
                style: TextStyle(
                    color: cores.primary, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
                'Informe o e-mail da sua conta. Vamos enviar um link para você '
                'criar uma nova senha.',
                style: TextStyle(color: cores.onSurfaceVariant)),
            const SizedBox(height: 18),
            AppField(
                label: 'E-mail',
                hint: 'voce@email.com',
                controller: _email,
                keyboard: TextInputType.emailAddress,
                validator: validateEmail),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                  child: OutlineButtonX(
                      text: 'Voltar', onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(
                  child: PrimaryButton(
                      text: 'Enviar', onPressed: _enviar, loading: _loading)),
            ]),
          ]),
        ),
      ),
    );
  }
}
