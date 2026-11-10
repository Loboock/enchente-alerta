import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editText(BuildContext c,
      {required String title,
      required String initial,
      required String hint,
      required void Function(String) onSave}) async {
    final ctrl = TextEditingController(text: initial);
    final ok = await showDialog<bool>(
      context: c,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true) {
      onSave(ctrl.text.trim());
      if (c.mounted) showMsg(c, 'Salvo com sucesso.');
    }
  }

  Future<void> _notifications(BuildContext c, bool current) async {
    bool value = current;
    final ok = await showDialog<bool>(
      context: c,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Notificações'),
          content: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Receber alertas de alagamento'),
            value: value,
            onChanged: (v) => setS(() => value = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (ok == true) {
      AuthService.instance.updateProfile(notificacoes: value);
      if (c.mounted) showMsg(c, 'Preferência salva.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return AppShell(
      title: 'Perfil',
      child: AnimatedBuilder(
        animation: auth,
        builder: (context, _) {
          final u = auth.user;
          if (u == null) return const SizedBox();
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kBlue,
                child: Text(u.nome.isNotEmpty ? u.nome[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.nome,
                    style: const TextStyle(
                        color: kBlue, fontWeight: FontWeight.w700, fontSize: 12)),
                Text(u.email, style: const TextStyle(color: kGrey, fontSize: 10)),
              ]),
            ]),
            const SizedBox(height: 12),
            _Item(
                'Meus dados',
                () => _editText(context,
                    title: 'Meus dados',
                    initial: u.nome,
                    hint: 'Seu nome',
                    onSave: (v) => auth.updateProfile(nome: v))),
            _Item('Notificações', () => _notifications(context, u.notificacoes)),
            _Item(
                'Endereço padrão',
                () => _editText(context,
                    title: 'Endereço padrão',
                    initial: u.endereco,
                    hint: 'Rua, número, bairro',
                    onSave: (v) => auth.updateProfile(endereco: v))),
            _Item('Sair', () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sair'),
                  content: const Text('Deseja sair da sua conta?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sair')),
                  ],
                ),
              );
              if (ok == true) auth.signOut();
            }),
          ]);
        },
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _Item(this.text, this.onTap);

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
          child: Row(children: [
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF3A4152)))),
            const Icon(Icons.chevron_right, size: 16, color: kGrey),
          ]),
        ),
      );
}
