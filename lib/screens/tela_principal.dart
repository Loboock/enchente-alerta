import 'package:flutter/material.dart';

import '../widgets/barra_navegacao_inferior.dart';
import 'inicio/tela_inicio.dart';
import 'tela_em_construcao.dart';

/// Estrutura principal do app: telas das cinco abas + barra inferior.
class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  static const _itens = [
    ItemNavegacao(rotulo: 'Início', icone: Icons.home_outlined),
    ItemNavegacao(rotulo: 'Avisos', icone: Icons.notifications_none),
    ItemNavegacao(rotulo: 'Histórico', icone: Icons.history_toggle_off),
    ItemNavegacao(rotulo: 'Perfil', icone: Icons.person_outline),
    ItemNavegacao(rotulo: 'Guia', icone: Icons.menu_book_outlined),
  ];

  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantém o mapa vivo ao trocar de aba (não recarrega).
      body: IndexedStack(
        index: _indice,
        children: const [
          TelaInicio(),
          TelaEmConstrucao(titulo: 'Avisos'),
          TelaEmConstrucao(titulo: 'Histórico'),
          TelaEmConstrucao(titulo: 'Perfil'),
          TelaEmConstrucao(titulo: 'Guia'),
        ],
      ),
      bottomNavigationBar: BarraNavegacaoInferior(
        itens: _itens,
        indiceAtual: _indice,
        aoSelecionar: (i) => setState(() => _indice = i),
      ),
    );
  }
}
