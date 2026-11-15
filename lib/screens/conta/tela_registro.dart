import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/widgets_conta.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
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

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.register(_email.text, _pass.text);
      if (!mounted) return;
      showMsg(context, 'Conta criada com sucesso.');
      // Volta para a aba Perfil, que agora mostra os dados da conta.
      Navigator.of(context).popUntil((r) => r.isFirst);
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
      appBar: barraConta(context, 'Cadastrar'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Criar conta',
                style: TextStyle(
                    color: cores.primary, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
                'Cadastre-se para receber alertas de alagamento da sua região em tempo real.',
                style: TextStyle(color: cores.onSurfaceVariant)),
            const SizedBox(height: 18),
            AppField(
                label: 'E-mail',
                hint: 'voce@email.com',
                controller: _email,
                keyboard: TextInputType.emailAddress,
                validator: validateEmail),
            AppField(
                label: 'Senha',
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
                      text: 'Voltar', onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(
                  child: PrimaryButton(
                      text: 'Cadastrar', onPressed: _register, loading: _loading)),
            ]),
          ]),
        ),
      ),
    );
  }
}
