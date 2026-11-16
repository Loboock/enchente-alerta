import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/dados_provisorios.dart';
import '../../models/destino.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/avisos.dart';
import '../../utils/cores_gravidade.dart';
import '../../utils/formatacao.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/atribuicao_mapa.dart';
import '../../widgets/scaffold_com_abas.dart';

/// Abre a rota de fuga do usuário até [destino].
void abrirRotaFuga(BuildContext context, Destino destino) {
  FocusScope.of(context).unfocus();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TelaRotaFuga(
        destino: destino,
        rota: rotaProvisoria(usuarioProvisorio, destino),
        observacao: observacaoProvisoria,
      ),
    ),
  );
}

/// Tela "02 Rota de fuga" do protótipo: mapa com o traçado em vermelho e o
/// painel com distância, tempo e risco.
class TelaRotaFuga extends StatelessWidget {
  const TelaRotaFuga({
    super.key,
    required this.destino,
    required this.rota,
    required this.observacao,
  });

  final Destino destino;
  final RotaFuga rota;
  final String observacao;

  @override
  Widget build(BuildContext context) {
    return ScaffoldComAbas(
      appBar: const AppBarTela(
        titulo: 'Rota de fuga',
        subtitulo: 'Menor risco até o abrigo',
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _MapaRota(rota: rota, destino: destino),
          const Positioned(top: 8, right: 8, child: AtribuicaoMapa()),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: _PainelRota(rota, observacao),
          ),
        ],
      ),
    );
  }
}

class _MapaRota extends StatelessWidget {
  const _MapaRota({required this.rota, required this.destino});

  final RotaFuga rota;
  final Destino destino;

  static const _azulUsuario = Color(0xFF2F5BD9);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        // Enquadra a rota inteira, deixando espaço embaixo para o painel.
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(rota.pontos),
          padding: const EdgeInsets.fromLTRB(48, 56, 48, 290),
          maxZoom: 17,
        ),
        minZoom: 8,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'br.unit.enchentealerta.enchente_alerta',
          errorTileCallback: (tile, error, stackTrace) {},
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: rota.pontos,
              strokeWidth: 4,
              color: AppColors.perigo,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            _pino(
              ponto: destino.posicao,
              cor: AppColors.seguro,
              rotulo: destino.nome,
            ),
            _pino(
              ponto: rota.pontos.first,
              cor: _azulUsuario,
              rotulo: 'Você está aqui',
            ),
          ],
        ),
      ],
    );
  }

  Marker _pino({
    required LatLng ponto,
    required Color cor,
    required String rotulo,
  }) {
    return Marker(
      point: ponto,
      width: 28,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 4),
                ],
              ),
            ),
          ),
          Positioned(
            top: 32,
            left: -80,
            right: -80,
            child: Text(
              rotulo,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                shadows: [
                  Shadow(color: Colors.white, blurRadius: 3),
                  Shadow(color: Colors.white, blurRadius: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PainelRota extends StatelessWidget {
  const _PainelRota(this.rota, this.observacao);

  final RotaFuga rota;
  final String observacao;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final distancia = formatarDistancia(rota.distanciaMetros, compacto: true);
    final risco = rota.riscoNaVia;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Material(
        color: cores.surface,
        elevation: 4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Dado(valor: distancia, rotulo: 'distância'),
                      _Dado(valor: '${rota.tempoAPeMin} min', rotulo: 'a pé'),
                      _Dado(
                        valor: risco.rotulo,
                        rotulo: 'risco via alt.',
                        cor: risco.cor(cores),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _Dado(valor: distancia, rotulo: 'distância'),
                      _Dado(
                        valor: '${rota.tempoCarroMin} min',
                        rotulo: 'de carro',
                      ),
                      _Dado(
                        valor: risco.rotulo,
                        rotulo: 'risco via alt.',
                        cor: risco.cor(cores),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    observacao,
                    style: TextStyle(fontSize: 13, color: cores.onSurface),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => avisoEmBreve(context, 'Navegação'),
                child: const Text('Iniciar navegação'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Um número em destaque com o rótulo pequeno embaixo.
class _Dado extends StatelessWidget {
  const _Dado({required this.valor, required this.rotulo, this.cor});

  final String valor;
  final String rotulo;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cor ?? cores.primary,
            ),
          ),
          Text(
            rotulo,
            style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
