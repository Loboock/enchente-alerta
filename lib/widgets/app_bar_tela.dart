import 'package:flutter/material.dart';

import 'ajuda.dart';

/// Cabeçalho azul das telas: título (com subtítulo opcional) e o botão de
/// ajuda "i".
///
/// - Com [ajuda]: o botão mostra o texto próprio da tela, com o atalho para
///   a tela Ajuda completa.
/// - Sem [ajuda] (Início): o botão abre direto a tela Ajuda.
/// - Na própria Ajuda ([ajudaAtiva]) ele fica laranja, como no protótipo, e
///   não abre outra Ajuda por cima.
class AppBarTela extends StatelessWidget implements PreferredSizeWidget {
  const AppBarTela({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.ajuda,
    this.ajudaAtiva = false,
    this.acoesExtras = const [],
    this.voltar = false,
  });

  final String titulo;
  final String? subtitulo;
  final String? ajuda;
  final bool ajudaAtiva;

  /// Botões que ficam à esquerda do "i" (ex.: modo escuro no Início).
  final List<Widget> acoesExtras;

  /// Seta de voltar à esquerda do título (telas do Painel da Defesa Civil).
  /// As telas do protótipo não têm a seta; nelas fica desligada.
  final bool voltar;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final subtitulo = this.subtitulo;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: voltar ? const BackButton(color: Colors.white) : null,
      centerTitle: false,
      toolbarHeight: 72,
      titleSpacing: voltar ? 0 : 20,
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
        ...acoesExtras,
        BotaoAjuda(texto: ajuda, ativa: ajudaAtiva),
        const SizedBox(width: 12),
      ],
    );
  }
}
