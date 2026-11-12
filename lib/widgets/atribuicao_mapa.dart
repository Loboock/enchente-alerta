import 'package:flutter/material.dart';

/// Crédito do OpenStreetMap, exigido pela licença dos dados do mapa.
class AtribuicaoMapa extends StatelessWidget {
  const AtribuicaoMapa({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: const Color(0xCCFFFFFF),
      child: const Text(
        '© OpenStreetMap contributors',
        style: TextStyle(fontSize: 10, color: Colors.black87),
      ),
    );
  }
}
