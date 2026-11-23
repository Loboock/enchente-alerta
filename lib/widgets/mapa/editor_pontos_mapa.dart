import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'mapa_enchente.dart';

/// Mapa para a Defesa Civil desenhar tocando: cada toque marca um ponto.
/// Com [fechado] desenha uma área (polígono); sem, um caminho (linha).
class EditorPontosMapa extends StatelessWidget {
  const EditorPontosMapa({
    super.key,
    required this.pontos,
    required this.aoMudar,
    required this.cor,
    this.fechado = false,
    this.destino,
    this.altura = 320,
  });

  final List<LatLng> pontos;
  final ValueChanged<List<LatLng>> aoMudar;
  final Color cor;
  final bool fechado;

  /// Ponto de chegada mostrado no mapa (o abrigo da rota).
  final LatLng? destino;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: altura,
            child: MapaEnchente(
              centroInicial: pontos.isNotEmpty ? pontos.last : destino,
              zoomInicial: 15,
              mostrarRotasFuga: !fechado,
              aoTocar: (p) => aoMudar([...pontos, p]),
              camadasExtras: [
                if (fechado && pontos.length >= 3)
                  PolygonLayer(polygons: [
                    Polygon(
                      points: pontos,
                      color: cor.withValues(alpha: 0.25),
                      borderColor: cor,
                      borderStrokeWidth: 3,
                    ),
                  ]),
                if ((!fechado || pontos.length < 3) && pontos.length >= 2)
                  PolylineLayer(polylines: [
                    Polyline(points: pontos, color: cor, strokeWidth: 5),
                  ]),
                MarkerLayer(markers: [
                  if (destino != null)
                    Marker(
                      point: destino!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.home_work,
                          color: Colors.green, size: 34),
                    ),
                  for (var i = 0; i < pontos.length; i++)
                    Marker(
                      point: pontos[i],
                      width: 26,
                      height: 26,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                pontos.isEmpty
                    ? 'Toque no mapa para marcar os pontos.'
                    : '${pontos.length} ponto(s) marcado(s).',
                style: TextStyle(color: cores.onSurfaceVariant, fontSize: 13),
              ),
            ),
            TextButton.icon(
              onPressed: pontos.isEmpty
                  ? null
                  : () => aoMudar(pontos.sublist(0, pontos.length - 1)),
              icon: const Icon(Icons.undo),
              label: const Text('Desfazer'),
            ),
            TextButton(
              onPressed: pontos.isEmpty ? null : () => aoMudar(const []),
              child: const Text('Limpar'),
            ),
          ],
        ),
      ],
    );
  }
}
