import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Item da barra de navegação inferior.
class ItemNavegacao {
  const ItemNavegacao({required this.rotulo, required this.icone});

  final String rotulo;
  final IconData icone;
}

/// As cinco abas do app, na ordem em que aparecem na barra.
const itensNavegacao = [
  ItemNavegacao(rotulo: 'Início', icone: Icons.home_outlined),
  ItemNavegacao(rotulo: 'Avisos', icone: Icons.notifications_none),
  ItemNavegacao(rotulo: 'Histórico', icone: Icons.history_toggle_off),
  ItemNavegacao(rotulo: 'Perfil', icone: Icons.person_outline),
  ItemNavegacao(rotulo: 'Guia', icone: Icons.menu_book_outlined),
];

/// Barra inferior azul do protótipo: ícone + rótulo, com o item ativo em
/// laranja de alerta (RNF10 — alto contraste). Com `indiceAtual` -1 nenhuma
/// aba fica ativa (telas abertas por cima, como Abrigos e Rota de fuga).
class BarraNavegacaoInferior extends StatelessWidget {
  const BarraNavegacaoInferior({
    super.key,
    required this.itens,
    required this.indiceAtual,
    required this.aoSelecionar,
  });

  final List<ItemNavegacao> itens;
  final int indiceAtual;
  final ValueChanged<int> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    final fundo = Theme.of(context).appBarTheme.backgroundColor;

    return Material(
      color: fundo,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var i = 0; i < itens.length; i++)
                Expanded(
                  child: _BotaoNavegacao(
                    item: itens[i],
                    ativo: i == indiceAtual,
                    aoTocar: () => aoSelecionar(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotaoNavegacao extends StatelessWidget {
  const _BotaoNavegacao({
    required this.item,
    required this.ativo,
    required this.aoTocar,
  });

  final ItemNavegacao item;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? AppColors.alerta : AppColors.azulClaro;

    return Semantics(
      button: true,
      selected: ativo,
      label: item.rotulo,
      child: InkWell(
        onTap: aoTocar,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icone, size: 28, color: cor),
              const SizedBox(height: 4),
              Text(
                item.rotulo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                  color: cor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
