import 'package:flutter/material.dart';

/// Botão redondo flutuante sobre o mapa (recentralizar, reportar...).
class BotaoMapa extends StatelessWidget {
  const BotaoMapa({
    super.key,
    required this.icone,
    required this.dica,
    required this.aoTocar,
    this.cor,
    this.corIcone,
    this.tamanho = 52,
  });

  final IconData icone;
  final String dica;
  final VoidCallback aoTocar;
  final Color? cor;
  final Color? corIcone;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Tooltip(
      message: dica,
      child: Material(
        color: cor ?? cores.surface,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: aoTocar,
          child: SizedBox(
            width: tamanho,
            height: tamanho,
            child: Icon(
              icone,
              size: tamanho * 0.5,
              color: corIcone ?? cores.primary,
              semanticLabel: dica,
            ),
          ),
        ),
      ),
    );
  }
}
