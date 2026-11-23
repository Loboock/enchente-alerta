import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/guias_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../offline/tela_mapa_offline.dart';

/// Tela "08 Guia de segurança" do protótipo: orientações para antes, durante
/// e se precisar evacuar, mais os telefones de emergência.
class TelaGuia extends StatelessWidget {
  const TelaGuia({super.key, this.orientacoes});

  /// Orientações a exibir. Sem nada, usa as publicadas pela Defesa Civil
  /// no Firestore (ou o guia de exemplo, se nenhuma foi publicada).
  final List<GuiaOrientacao>? orientacoes;

  // Fases mostradas no protótipo, na ordem da tela. A fase `depois` existe
  // no modelo, mas não tem seção no protótipo.
  static const _secoes = [
    (FaseGuia.antes, 'Antes'),
    (FaseGuia.durante, 'Durante'),
    (FaseGuia.evacuacao, 'Se precisar evacuar'),
    (FaseGuia.emergencia, 'Emergência'),
  ];

  @override
  Widget build(BuildContext context) {
    final servico = GuiasService.instance..iniciar();
    return ValueListenableBuilder<List<GuiaOrientacao>>(
      valueListenable: servico.publicadas,
      builder: (context, _, _) =>
          _conteudo(context, orientacoes ?? servico.paraMoradores),
    );
  }

  Widget _conteudo(BuildContext context, List<GuiaOrientacao> guias) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AppBarTela(
        titulo: 'Guia de segurança',
        subtitulo: 'Antes, durante e depois',
        ajuda: TextosAjuda.guia,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          Semantics(
            header: true,
            child: Text(
              'Guia de segurança',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cores.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Preparação também é deixar o mapa salvo para usar sem internet.
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.download_for_offline_outlined,
                  color: cores.primary, size: 32),
              title: const Text('Salve o mapa da região'),
              subtitle: const Text('Para usar o mapa mesmo sem internet'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const TelaMapaOffline(abaAtiva: 4))),
            ),
          ),
          for (final (fase, titulo) in _secoes) ...[
            const SizedBox(height: 20),
            _SecaoGuia(
              titulo: titulo,
              itens: GuiaOrientacao.filtrarPorFase(guias, fase),
            ),
          ],
        ],
      ),
    );
  }
}

class _SecaoGuia extends StatelessWidget {
  const _SecaoGuia({required this.titulo, required this.itens});

  final String titulo;
  final List<GuiaOrientacao> itens;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    // Cabeçalho azul com texto branco nos dois temas (RNF10).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.azul,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Semantics(
            header: true,
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cores.surface,
            border: Border.all(color: cores.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in itens)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: TextStyle(color: cores.onSurface)),
                      Expanded(
                        child: Text(
                          item.conteudo,
                          style: TextStyle(
                            fontSize: 14,
                            color: cores.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
