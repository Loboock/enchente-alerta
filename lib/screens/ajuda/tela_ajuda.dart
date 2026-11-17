import 'package:flutter/material.dart';

import '../../navegacao.dart';
import '../../utils/exigir_login.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../abrigos/tela_abrigos_proximos.dart';
import '../avisos/tela_criar_aviso.dart';
import '../conta/tela_registro.dart';
import '../conta/tela_reset_senha.dart';
import '../rota/tela_escolher_destino.dart';

/// Abre a tela de ajuda por cima da tela atual.
void abrirAjuda(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const TelaAjuda()),
  );
}

/// Tela "13 Ajuda" do protótipo: índice das telas do app. Tocar em um item
/// leva até a tela correspondente.
class TelaAjuda extends StatelessWidget {
  const TelaAjuda({super.key});

  void _empurrar(BuildContext context, Widget tela) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela));
  }

  Future<void> _criarAviso(BuildContext context) async {
    if (!exigirLogin(context, acao: 'criar avisos')) return;
    final criado = await abrirCriarAviso(context);
    if (criado == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Aviso criado! Ele já aparece no mapa e em Avisos.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Abas: 0 Início, 1 Avisos, 2 Histórico, 3 Perfil, 4 Guia.
    final itens = <(String, VoidCallback)>[
      ('Início', () => irParaAba(context, 0)),
      (
        'Rota de fuga',
        () => _empurrar(context, const TelaEscolherDestino()),
      ),
      (
        'Abrigos próximos',
        () => _empurrar(context, const TelaAbrigosProximos()),
      ),
      ('Histórico', () => irParaAba(context, 2)),
      ('Avisos', () => irParaAba(context, 1)),
      ('Criar avisos', () => _criarAviso(context)),
      // Para reportar, a pessoa escolhe o aviso na lista (botão Reportar).
      ('Reportar avisos', () => irParaAba(context, 1)),
      ('Guia de segurança', () => irParaAba(context, 4)),
      // Sem conta, a aba Perfil mostra o login.
      ('Login', () => irParaAba(context, 3)),
      ('Cadastro', () => _empurrar(context, const RegisterScreen())),
      (
        'Esqueceu a senha',
        () => _empurrar(context, const ResetPasswordScreen()),
      ),
    ];

    return ScaffoldComAbas(
      appBar: const AppBarTela(titulo: 'Ajuda', ajudaAtiva: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          for (final (rotulo, aoTocar) in itens)
            _ItemAjuda(rotulo: rotulo, aoTocar: aoTocar),
        ],
      ),
    );
  }
}

class _ItemAjuda extends StatelessWidget {
  const _ItemAjuda({required this.rotulo, required this.aoTocar});

  final String rotulo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: rotulo,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: aoTocar,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cores.outline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rotulo,
                    style: TextStyle(fontSize: 16, color: cores.onSurface),
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
