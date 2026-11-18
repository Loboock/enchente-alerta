import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/widgets_conta.dart';
import 'tela_login.dart';

/// Aba Perfil: mostra o login para quem não tem conta (Visitante) e os dados
/// da conta para quem está logado.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editText(BuildContext c,
      {required String title,
      required String initial,
      required String hint,
      required Future<void> Function(String) onSave}) async {
    final ctrl = TextEditingController(text: initial);
    final ok = await showDialog<bool>(
      context: c,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    final texto = ctrl.text.trim();
    if (ok != true || texto.isEmpty) return;
    try {
      await onSave(texto);
      if (c.mounted) showMsg(c, 'Salvo com sucesso.');
    } catch (e) {
      if (c.mounted) showMsg(c, AuthService.message(e));
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
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await AuthService.instance.updateProfile(notificacoes: value);
      if (c.mounted) showMsg(c, 'Preferência salva.');
    } catch (e) {
      if (c.mounted) showMsg(c, AuthService.message(e));
    }
  }

  Future<void> _sair(BuildContext c) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja sair da sua conta?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AuthService.instance.signOut();
    } catch (e) {
      if (c.mounted) showMsg(c, AuthService.message(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        final u = auth.user;
        // Visitante: a aba Perfil vira a tela de login.
        if (u == null) return const LoginScreen();

        final cores = Theme.of(context).colorScheme;
        final nome = auth.nome;
        return Scaffold(
          appBar: barraConta(context, 'Perfil', ajuda: TextosAjuda.perfil),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: cores.primary,
                foregroundColor: cores.onPrimary,
                child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nome,
                      style: TextStyle(
                          color: cores.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                  Text(u.email ?? '', style: TextStyle(color: cores.onSurfaceVariant)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            _Item(
                'Meus dados',
                () => _editText(context,
                    title: 'Meus dados',
                    initial: nome,
                    hint: 'Seu nome',
                    onSave: (v) => auth.updateProfile(nome: v))),
            _Item('Notificações',
                () => _notifications(context, auth.notificacoesAtivas)),
            // O endereço precisa da localização no mapa (subcoleção
            // usuarios/{uid}/enderecos); entra junto com a tela do mapa.
            _Item('Endereço padrão',
                () => showMsg(context, 'Endereço padrão: em breve')),
            _Item('Sair', () => _sair(context)),
          ]),
        );
      },
    );
  }
}

class _Item extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _Item(this.text, this.onTap);

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration:
            BoxDecoration(border: Border(bottom: BorderSide(color: cores.outline))),
        child: Row(children: [
          Expanded(child: Text(text, style: TextStyle(color: cores.onSurface))),
          Icon(Icons.chevron_right, color: cores.onSurfaceVariant),
        ]),
      ),
    );
  }
}
