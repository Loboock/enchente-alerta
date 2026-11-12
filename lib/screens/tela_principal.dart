import 'package:flutter/material.dart';

import '../navegacao.dart';
import '../widgets/barra_navegacao_inferior.dart';
import 'inicio/tela_inicio.dart';
import 'tela_em_construcao.dart';

/// Estrutura principal do app: telas das cinco abas + barra inferior.
class TelaPrincipal extends StatelessWidget {
  const TelaPrincipal({super.key});

  static const _telas = <Widget>[
    TelaInicio(),
    TelaEmConstrucao(titulo: 'Avisos'),
    TelaEmConstrucao(titulo: 'Histórico'),
    TelaEmConstrucao(titulo: 'Perfil'),
    TelaEmConstrucao(titulo: 'Guia'),
  ];

  @override
  Widget build(BuildContext context) {
    // A aba escolhida fica em `abaAtual` para que as telas abertas por cima
    // (abrigos, rota) também consigam trocar de aba.
    return ValueListenableBuilder<int>(
      valueListenable: abaAtual,
      builder: (context, indice, _) => Scaffold(
        // IndexedStack mantém o mapa vivo ao trocar de aba (não recarrega).
        body: IndexedStack(index: indice, children: _telas),
        bottomNavigationBar: BarraNavegacaoInferior(
          itens: itensNavegacao,
          indiceAtual: indice,
          aoSelecionar: (i) => abaAtual.value = i,
        ),
      ),
    );
  }
}
