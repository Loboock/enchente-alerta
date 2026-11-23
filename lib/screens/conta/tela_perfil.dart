import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/widgets_conta.dart';
import '../defesa_civil/tela_painel_defesa_civil.dart';
import 'tela_login.dart';
import 'tela_meus_dados.dart';

/// Aba Perfil: mostra o login para quem não tem conta (Visitante), o painel
/// para a Defesa Civil e, para o morador, o perfil no formato dos apps
/// comuns: nome em destaque e as opções agrupadas, com "Sair" no fim.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _abrirMeusDados(BuildContext context) {
    final auth = AuthService.instance;
    final email = auth.user?.email ?? '';
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TelaMeusDados(
        nome: auth.nome,
        email: email,
        perfil: auth.usuario?.perfil ?? PerfilUsuario.morador,
        criadaEm: auth.usuario?.criadoEm,
        aoSalvarNome: (nome) => auth.updateProfile(nome: nome),
        aoAlterarSenha: () => auth.resetPassword(email),
      ),
    ));
  }

  Future<void> _alterarNotificacoes(BuildContext c, bool ativas) async {
    try {
      await AuthService.instance.updateProfile(notificacoes: ativas);
      if (c.mounted) {
        showMsg(c, ativas ? 'Alertas ativados.' : 'Alertas desativados.');
      }
    } catch (e) {
      if (c.mounted) showMsg(c, AuthService.message(e));
    }
  }

  Future<void> _sair(BuildContext c) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você continua usando o app como visitante.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sair')),
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

        // Defesa Civil: perfil diferente, com o painel de gestão.
        if (auth.usuario?.ehDefesaCivil ?? false) {
          return TelaPainelDefesaCivil(
            nome: auth.nome,
            aoEditarDados: () => _abrirMeusDados(context),
            aoSair: () => _sair(context),
          );
        }

        return PerfilMorador(
          nome: auth.nome,
          notificacoesAtivas: auth.notificacoesAtivas,
          aoMeusDados: () => _abrirMeusDados(context),
          aoMudarNotificacoes: (v) => _alterarNotificacoes(context, v),
          aoEnderecoPadrao: () =>
              showMsg(context, 'Endereço padrão: em breve'),
          aoSair: () => _sair(context),
        );
      },
    );
  }
}

/// Conteúdo do Perfil do morador, separado para ser testado sem o Firebase.
class PerfilMorador extends StatelessWidget {
  const PerfilMorador({
    super.key,
    required this.nome,
    required this.notificacoesAtivas,
    required this.aoMeusDados,
    required this.aoMudarNotificacoes,
    required this.aoEnderecoPadrao,
    required this.aoSair,
  });

  final String nome;
  final bool notificacoesAtivas;
  final VoidCallback aoMeusDados;
  final ValueChanged<bool> aoMudarNotificacoes;
  final VoidCallback aoEnderecoPadrao;
  final VoidCallback aoSair;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: barraConta(context, 'Perfil', ajuda: TextosAjuda.perfil),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          // Cabeçalho: só a inicial e o nome, como nos apps comuns. O e-mail
          // fica em "Meus dados".
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: cores.primary,
              foregroundColor: cores.onPrimary,
              child: Text(
                nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nome,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cores.primary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const _Secao('Conta'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Meus dados'),
            subtitle: const Text('Nome, e-mail e senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: aoMeusDados,
          ),
          const Divider(indent: 16, endIndent: 16),
          const _Secao('Preferências'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Alertas de alagamento'),
            subtitle: Text(notificacoesAtivas
                ? 'Avisos da Defesa Civil no Início'
                : 'Desativados'),
            value: notificacoesAtivas,
            onChanged: aoMudarNotificacoes,
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Endereço padrão'),
            subtitle: const Text('Sua casa, para alertas da região'),
            trailing: const Icon(Icons.chevron_right),
            onTap: aoEnderecoPadrao,
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.logout, color: cores.error),
            title: Text(
              'Sair',
              style: TextStyle(color: cores.error, fontWeight: FontWeight.w600),
            ),
            onTap: aoSair,
          ),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      );
}
