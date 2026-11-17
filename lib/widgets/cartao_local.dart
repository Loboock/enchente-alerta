import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cartão de uma linha: ícone azul, nome, detalhe e distância opcional.
/// Usado na lista de abrigos e na escolha de destino.
class CartaoLocal extends StatelessWidget {
  const CartaoLocal({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.aoTocar,
    this.distancia,
  });

  final String titulo;
  final String subtitulo;
  final IconData icone;
  final String? distancia;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final distancia = this.distancia;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: cores.surface,
        elevation: 1.5,
        shadowColor: Colors.black26,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: cores.outline),
        ),
        child: InkWell(
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.azul,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icone, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cores.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 12,
                          color: cores.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (distancia != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    distancia,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cores.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
