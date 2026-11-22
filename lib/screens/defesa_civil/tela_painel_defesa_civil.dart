import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/abrigos_service.dart';
import '../../services/alertas_service.dart';
import '../../services/defesa_civil_service.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import 'tela_abrigos_defesa_civil.dart';
import 'tela_alertas_defesa_civil.dart';
import 'tela_denuncias.dart';

/// Aba Perfil das contas da Defesa Civil: no lugar dos dados de morador,
/// um painel com o que só esse perfil pode fazer (denúncias, alertas e
/// abrigos) e, embaixo, os dados da conta.
class TelaPainelDefesaCivil extends StatefulWidget {
  const TelaPainelDefesaCivil({
    super.key,
    required this.nome,
    required this.email,
    required this.aoEditarDados,
    required this.aoSair,
  });

  final String nome;
  final String email;
  final VoidCallback aoEditarDados;
  final VoidCallback aoSair;

  @override
  State<TelaPainelDefesaCivil> createState() => _TelaPainelDefesaCivilState();
}

class _TelaPainelDefesaCivilState extends State<TelaPainelDefesaCivil> {
  @override
  void initState() {
    super.initState();
    DefesaCivilService.instance.iniciar();
    AlertasService.instance.iniciar();
    AbrigosService.instance.iniciar();
  }

  @override
  void dispose() {
    // Ao sair da conta o painel some; sem a permissão, a consulta das
    // denúncias passaria a dar erro.
    DefesaCivilService.instance.parar();
    super.dispose();
  }

  void _abrir(Widget tela) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final dc = DefesaCivilService.instance;
    final alertas = AlertasService.instance;
    final abrigos = AbrigosService.instance;

    return Scaffold(
      appBar: const AppBarTela(
        titulo: 'Painel da Defesa Civil',
        subtitulo: 'Acesso restrito',
        ajuda: TextosAjuda.painelDefesaCivil,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Cabecalho(nome: widget.nome, email: widget.email),
          const SizedBox(height: 24),
          _TituloSecao('Gerenciar'),
          ValueListenableBuilder<List<GrupoDenuncias>>(
            valueListenable: dc.pendentes,
            builder: (context, grupos, _) => _CartaoPainel(
              icone: Icons.flag_outlined,
              titulo: 'Denúncias',
              detalhe: switch (grupos.length) {
                0 => 'Nenhum aviso para revisar',
                1 => '1 aviso para revisar',
                final n => '$n avisos para revisar',
              },
              destaque: grupos.isNotEmpty,
              aoTocar: () => _abrir(const TelaDenuncias()),
            ),
          ),
          ValueListenableBuilder<List<Alerta>>(
            valueListenable: alertas.alertas,
            builder: (context, _, _) {
              final ativos = alertas.ativos().length;
              return _CartaoPainel(
                icone: Icons.warning_amber_rounded,
                titulo: 'Alertas',
                detalhe: switch (ativos) {
                  0 => 'Nenhum alerta ativo · emitir alerta',
                  1 => '1 alerta ativo agora',
                  final n => '$n alertas ativos agora',
                },
                aoTocar: () => _abrir(const TelaAlertasDefesaCivil()),
              );
            },
          ),
          ValueListenableBuilder<List<Abrigo>>(
            valueListenable: abrigos.cadastrados,
            builder: (context, lista, _) => _CartaoPainel(
              icone: Icons.home_work_outlined,
              titulo: 'Abrigos',
              detalhe: switch (lista.length) {
                0 => 'Nenhum cadastrado (moradores veem os de exemplo)',
                1 => '1 abrigo cadastrado',
                final n => '$n abrigos cadastrados',
              },
              aoTocar: () => _abrir(const TelaAbrigosDefesaCivil()),
            ),
          ),
          const SizedBox(height: 24),
          _TituloSecao('Conta'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.badge_outlined, color: cores.primary),
            title: const Text('Meus dados'),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.aoEditarDados,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: cores.primary),
            title: const Text('Sair'),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.aoSair,
          ),
        ],
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.nome, required this.email});

  final String nome;
  final String email;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cores.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cores.secondary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.shield_outlined, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cores.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DEFESA CIVIL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  nome,
                  style: TextStyle(
                    color: cores.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(email, style: TextStyle(color: cores.onPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          texto,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

/// Cartão grande do painel: ícone, título, situação e seta.
class _CartaoPainel extends StatelessWidget {
  const _CartaoPainel({
    required this.icone,
    required this.titulo,
    required this.detalhe,
    required this.aoTocar,
    this.destaque = false,
  });

  final IconData icone;
  final String titulo;
  final String detalhe;
  final VoidCallback aoTocar;

  /// Laranja quando há algo esperando a Defesa Civil (ex.: denúncias).
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final cor = destaque ? cores.secondary : cores.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cores.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: destaque ? cor : cores.outline, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icone, color: cor, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          color: cores.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detalhe,
                        style: TextStyle(
                          color: destaque ? cor : cores.onSurfaceVariant,
                          fontWeight:
                              destaque ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cores.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
