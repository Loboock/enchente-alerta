import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/widgets_conta.dart';
import 'tela_registro.dart';
import 'tela_reset_senha.dart';

/// Aparece na aba Perfil quando a pessoa não está logada. O app nunca pede
/// login ao abrir: o Visitante usa as outras abas sem conta.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email =
      TextEditingController(text: AuthService.instance.savedEmail ?? '');
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
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: barraConta(context, 'Entrar', ajuda: TextosAjuda.login),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                  color: cores.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cores.outline)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const _Logo(),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Enchente Alerta',
                      style: TextStyle(
                          color: cores.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                  const SizedBox(height: 2),
                  Text('Informação que te protege',
                      style: TextStyle(color: cores.onSurfaceVariant, fontSize: 14)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
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
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => setState(() => _save = !_save),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Checkbox(
                        value: _save,
                        onChanged: (v) => setState(() => _save = v ?? false)),
                    Text('Salvar login',
                        style: TextStyle(color: cores.onSurfaceVariant)),
                  ]),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ResetPasswordScreen(email: _email.text))),
                  child: const Text('Esqueceu a senha?'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            PrimaryButton(text: 'Entrar', onPressed: _login, loading: _loading),
            const SizedBox(height: 14),
            OutlineButtonX(
                text: 'Cadastrar-se',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()))),
          ]),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(alignment: Alignment.center, children: [
        Positioned(
            top: 0,
            child: Icon(Icons.home_rounded,
                size: 56, color: cores.onPrimaryContainer)),
        const Positioned(
            top: 18,
            child: Icon(Icons.warning_rounded, size: 24, color: AppColors.alerta)),
        Positioned(
            bottom: -4, child: Icon(Icons.water, size: 34, color: cores.primary)),
      ]),
    );
  }
}
