import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(text: AuthService.instance.savedEmail ?? '');
  final _pass = TextEditingController();
  late bool _save = AuthService.instance.savedEmail != null;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.signIn(_email.text, _pass.text);
      AuthService.instance.savedEmail = _save ? _email.text.trim() : null;
    } catch (e) {
      if (mounted) showMsg(context, AuthService.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Entrar',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const _Logo(),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Enchente Alerta',
                      style: TextStyle(
                          color: kBlue, fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(height: 2),
                  Text('Informação que te protege',
                      style: TextStyle(color: kGrey, fontSize: 10)),
                ]),
              ]),
            ),
            const SizedBox(height: 18),
            AppField(
                label: 'E-mail',
                hint: 'voce@email.com',
                controller: _email,
                keyboard: TextInputType.emailAddress,
                validator: validateEmail),
            AppField(
                label: 'Senha',
                hint: '••••••••',
                controller: _pass,
                obscure: true,
                validator: (v) => (v ?? '').isEmpty ? 'Informe a senha' : null),
            Row(children: [
              InkWell(
                onTap: () => setState(() => _save = !_save),
                child: Row(children: [
                  Icon(_save ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 14, color: kGrey),
                  const SizedBox(width: 4),
                  const Text('Salvar login', style: TextStyle(color: kGrey, fontSize: 10)),
                ]),
              ),
              const Text('  |  ', style: TextStyle(color: kGrey, fontSize: 10)),
              InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ResetPasswordScreen(email: _email.text))),
                child: const Text('Esqueceu a senha?',
                    style: TextStyle(color: kGrey, fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 14),
            PrimaryButton(text: 'Entrar', onPressed: _login, loading: _loading),
            const SizedBox(height: 14),
            OutlineButtonX(
                text: 'Cadastrar-se',
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const RegisterScreen()))),
          ]),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 60,
        height: 60,
        child: Stack(alignment: Alignment.center, children: const [
          Positioned(top: 0, child: Icon(Icons.home_rounded, size: 56, color: Color(0xFF1F2F7A))),
          Positioned(top: 18, child: Icon(Icons.warning_rounded, size: 24, color: kOrange)),
          Positioned(bottom: -4, child: Icon(Icons.water, size: 34, color: Color(0xFF3B6FD8))),
        ]),
      );
}
