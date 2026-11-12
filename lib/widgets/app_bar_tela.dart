import 'package:flutter/material.dart';

import '../utils/avisos.dart';

/// Cabeçalho azul das telas: título (com subtítulo opcional) e botão de ajuda.
class AppBarTela extends StatelessWidget implements PreferredSizeWidget {
  const AppBarTela({super.key, required this.titulo, this.subtitulo});

  final String titulo;
  final String? subtitulo;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final subtitulo = this.subtitulo;

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: 72,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (subtitulo != null)
            Text(
              subtitulo,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Ajuda',
          iconSize: 40,
          padding: const EdgeInsets.all(4),
          color: Colors.white,
          icon: const Icon(Icons.help_outline),
          onPressed: () => avisoEmBreve(context, 'Ajuda'),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
