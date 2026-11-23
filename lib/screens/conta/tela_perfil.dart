import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/enderecos_service.dart';
import '../../services/notificacoes_service.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/widgets_conta.dart';
import '../defesa_civil/tela_painel_defesa_civil.dart';
import '../offline/tela_mapa_offline.dart';
import 'tela_enderecos.dart';
import 'tela_login.dart';
import 'tela_meus_dados.dart';
import 'tela_notificacoes.dart';

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

  void _abrir(BuildContext context, Widget tela) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => tela));

  Future<void> _alterarRaio(BuildContext c, double km) async {
    try {
      await AuthService.instance.updateProfile(raioKm: km);
      if (c.mounted) showMsg(c, 'Alertas num raio de ${_km(km)}.');
    } catch (e) {
      if (c.mounted) showMsg(c, AuthService.message(e));
    }
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
    final enderecos = EnderecosService.instance..iniciar();
    final notificacoes = NotificacoesService.instance..iniciar();
    return ListenableBuilder(
      listenable: Listenable.merge(
          [auth, enderecos.enderecos, notificacoes.notificacoes]),
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
          raioKm: auth.usuario?.preferenciaNotificacao?.raioKm ?? 2,
          enderecoPadrao: enderecos.padrao?.logradouro,
          naoLidas: notificacoes.naoLidas,
          aoMeusDados: () => _abrirMeusDados(context),
          aoNotificacoes: () => _abrir(context, const TelaNotificacoes()),
          aoMudarNotificacoes: (v) => _alterarNotificacoes(context, v),
          aoMudarRaio: (km) => _alterarRaio(context, km),
          aoEnderecoPadrao: () => _abrir(context, const TelaEnderecos()),
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
    this.raioKm = 2,
    this.enderecoPadrao,
    this.naoLidas = 0,
    this.aoNotificacoes,
    this.aoMudarRaio,
  });

  final String nome;
  final bool notificacoesAtivas;
  final double raioKm;

  /// Rua do endereço padrão, ou `null` se não houver.
  final String? enderecoPadrao;
  final int naoLidas;
  final VoidCallback aoMeusDados;
  final VoidCallback? aoNotificacoes;
  final ValueChanged<bool> aoMudarNotificacoes;
  final ValueChanged<double>? aoMudarRaio;
  final VoidCallback aoEnderecoPadrao;
  final VoidCallback aoSair;

  Future<void> _escolherRaio(BuildContext context) async {
    final km = await showDialog<double>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Raio dos alertas'),
        children: [
          RadioGroup<double>(
            groupValue: raioKm,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(
              children: [
                for (final op in raiosAlerta)
                  RadioListTile<double>(title: Text(_km(op)), value: op),
              ],
            ),
          ),
        ],
      ),
    );
    if (km != null && km != raioKm) aoMudarRaio?.call(km);
  }

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
          ListTile(
            leading: Badge(
              isLabelVisible: naoLidas > 0,
              label: Text('$naoLidas'),
              child: const Icon(Icons.notifications_none),
            ),
            title: const Text('Notificações'),
            subtitle: Text(naoLidas == 0
                ? 'Alertas recebidos'
                : naoLidas == 1
                    ? '1 não lida'
                    : '$naoLidas não lidas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: aoNotificacoes,
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
            leading: const Icon(Icons.radar),
            title: const Text('Raio dos alertas'),
            subtitle: Text('${_km(raioKm)} em volta do seu endereço'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _escolherRaio(context),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Endereço padrão'),
            subtitle: Text(enderecoPadrao ?? 'Cadastre sua casa'),
            trailing: const Icon(Icons.chevron_right),
            onTap: aoEnderecoPadrao,
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: const Text('Mapa sem internet'),
            subtitle: const Text('Salvar o mapa da região no aparelho'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const TelaMapaOffline(abaAtiva: 3))),
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

/// Opções de raio (em km) dos alertas por região. As regras do Firestore
/// aceitam até 50 km.
const raiosAlerta = <double>[1, 2, 5, 10, 20];

String _km(double km) =>
    '${km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toString().replaceAll('.', ',')} km';

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
