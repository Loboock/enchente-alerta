import 'package:flutter/material.dart';

import '../services/conexao_service.dart';
import '../theme/app_theme.dart';

/// Envolve o app inteiro (MaterialApp.builder): sem internet, mostra uma
/// faixa no rodapé de todas as telas avisando que os dados vêm do aparelho
/// (RNF05). Com internet, não ocupa espaço.
class ComFaixaSemInternet extends StatelessWidget {
  const ComFaixaSemInternet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConexaoService.instance.online,
      builder: (context, online, _) {
        if (online) return child;
        return Column(
          children: [
            Expanded(
              // A faixa já cuida da margem de baixo do aparelho.
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: child,
              ),
            ),
            const FaixaSemInternet(),
          ],
        );
      },
    );
  }
}

class FaixaSemInternet extends StatelessWidget {
  const FaixaSemInternet({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Material(
        color: AppColors.alerta,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: const [
                Icon(Icons.cloud_off, color: Colors.black87, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sem internet. Mostrando o mapa e os avisos salvos no '
                    'aparelho.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
