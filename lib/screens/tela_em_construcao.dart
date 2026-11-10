import 'package:flutter/material.dart';

/// Tela provisória das abas que ainda não foram implementadas.
class TelaEmConstrucao extends StatelessWidget {
  const TelaEmConstrucao({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        centerTitle: false,
        toolbarHeight: 72,
        titleSpacing: 20,
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: Center(
        child: Text(
          'Em construção',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
