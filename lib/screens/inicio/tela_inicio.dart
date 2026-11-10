import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_theme.dart';

/// Tela "01 Início" do protótipo: mapa com a área de risco em destaque,
/// atalhos de locais e os botões Abrigo e Rota de fuga.
class TelaInicio extends StatelessWidget {
  const TelaInicio({super.key});

  // Provisório: centro do mapa e da área de risco (Farolândia, Aracaju).
  // Depois virá da localização do usuário e da coleção `areasRisco`.
  static const _centro = LatLng(-10.9640, -37.0510);
  static const _raioAreaRiscoMetros = 150.0;

  void _emBreve(BuildContext context, String recurso) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$recurso: em breve')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        centerTitle: false,
        toolbarHeight: 72,
        titleSpacing: 20,
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        actions: [
          IconButton(
            tooltip: 'Ajuda',
            iconSize: 40,
            padding: const EdgeInsets.all(4),
            color: Colors.white,
            icon: const Icon(Icons.help_outline),
            onPressed: () => _emBreve(context, 'Ajuda'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          const Expanded(child: _MapaRisco()),
          _PainelAcoes(
            aoAbrigo: () => _emBreve(context, 'Abrigo'),
            aoRotaFuga: () => _emBreve(context, 'Rota de fuga'),
          ),
        ],
      ),
    );
  }
}

class _MapaRisco extends StatelessWidget {
  const _MapaRisco();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: TelaInicio._centro,
            initialZoom: 16,
            minZoom: 10,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.unit.enchentealerta.enchente_alerta',
              // Sem internet o mapa só fica sem imagem, sem quebrar a tela.
              errorTileCallback: (tile, error, stackTrace) {},
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: TelaInicio._centro,
                  radius: TelaInicio._raioAreaRiscoMetros,
                  useRadiusInMeter: true,
                  color: AppColors.perigo.withValues(alpha: 0.28),
                ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('© OpenStreetMap contributors'),
            ),
          ],
        ),
        const Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _AtalhosLocais(),
        ),
      ],
    );
  }
}

/// Barra azul sobre o mapa com os locais salvos (hospital, escola, bairro).
class _AtalhosLocais extends StatelessWidget {
  const _AtalhosLocais();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.azul,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.azulMarinho),
      ),
      child: const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Atalho(
              icone: Icons.location_on,
              cor: AppColors.perigo,
              texto: 'Hosp. Universitário',
            ),
            SizedBox(width: 14),
            _Atalho(
              icone: Icons.home,
              cor: AppColors.alerta,
              texto: 'Escola Exemplo',
            ),
            SizedBox(width: 14),
            _Atalho(
              icone: Icons.home,
              cor: AppColors.alerta,
              texto: 'Farolândia',
            ),
          ],
        ),
      ),
    );
  }
}

class _Atalho extends StatelessWidget {
  const _Atalho({
    required this.icone,
    required this.cor,
    required this.texto,
  });

  final IconData icone;
  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 18, color: cor),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }
}

class _PainelAcoes extends StatelessWidget {
  const _PainelAcoes({required this.aoAbrigo, required this.aoRotaFuga});

  final VoidCallback aoAbrigo;
  final VoidCallback aoRotaFuga;

  @override
  Widget build(BuildContext context) {
    final estilo = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: estilo,
            onPressed: aoAbrigo,
            child: const Text('Abrigo'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: estilo,
            onPressed: aoRotaFuga,
            child: const Text('Rota de fuga'),
          ),
        ],
      ),
    );
  }
}
