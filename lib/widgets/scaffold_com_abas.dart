import 'package:flutter/material.dart';

import '../navegacao.dart';
import 'barra_navegacao_inferior.dart';

/// Scaffold das telas que abrem por cima da principal: mantém a barra
/// inferior do protótipo (sem aba ativa) e some com ela quando o teclado abre.
class ScaffoldComAbas extends StatelessWidget {
  const ScaffoldComAbas({super.key, required this.appBar, required this.body});

  final PreferredSizeWidget appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final tecladoAberto = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: tecladoAberto
          ? null
          : BarraNavegacaoInferior(
              itens: itensNavegacao,
              indiceAtual: -1,
              aoSelecionar: (i) => irParaAba(context, i),
            ),
    );
  }
}
