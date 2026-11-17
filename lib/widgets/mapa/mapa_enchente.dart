import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../config.dart';
import '../../models/models.dart';
import '../../models/perigo.dart';
import '../../services/localizacao_service.dart';
import '../../services/perigos_service.dart';
import '../../theme/app_theme.dart';
import 'folha_perigo.dart';

/// Mapa usado em todas as telas, no estilo do Waze: fundo do mapa,
/// alagamentos em tempo real e a seta azul do usuário.
///
/// Fundo: CARTO (visual limpo) se houver `CARTO_API_KEY`; senão,
/// OpenStreetMap padrão, que não precisa de chave.
///
/// As telas acrescentam o que é delas (linha da rota, pino do destino) em
/// [camadasExtras], que ficam entre os alagamentos e a seta do usuário.
class MapaEnchente extends StatelessWidget {
  const MapaEnchente({
    super.key,
    this.controller,
    this.centroInicial,
    this.zoomInicial = 16,
    this.enquadramentoInicial,
    this.camadasExtras = const [],
    this.aoFicarPronto,
    this.aoMexerNoMapa,
    this.mostrarPerigos = true,
  });

  final MapController? controller;
  final LatLng? centroInicial;
  final double zoomInicial;
  final CameraFit? enquadramentoInicial;
  final List<Widget> camadasExtras;
  final VoidCallback? aoFicarPronto;

  /// Chamado quando a PESSOA arrasta/gira/dá zoom (não quando o app move).
  final VoidCallback? aoMexerNoMapa;
  final bool mostrarPerigos;

  static const _gestosDoUsuario = {
    MapEventSource.dragStart,
    MapEventSource.onDrag,
    MapEventSource.multiFingerGestureStart,
    MapEventSource.onMultiFinger,
    MapEventSource.doubleTap,
    MapEventSource.scrollWheel,
  };

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: centroInicial ??
            LocalizacaoService.instance.posicao.value?.ponto ??
            const LatLng(-10.9640, -37.0510),
        initialZoom: zoomInicial,
        initialCameraFit: enquadramentoInicial,
        minZoom: 5,
        maxZoom: 19,
        backgroundColor:
            escuro ? const Color(0xFF1B1E24) : const Color(0xFFF2EFE9),
        // Depois do primeiro quadro: aí já dá para mover o mapa e chamar
        // setState sem conflito com a construção da tela.
        onMapReady: aoFicarPronto == null
            ? null
            : () => WidgetsBinding.instance.addPostFrameCallback(
                  (_) => aoFicarPronto!(),
                ),
        onMapEvent: aoMexerNoMapa == null
            ? null
            : (evento) {
                if (_gestosDoUsuario.contains(evento.source)) {
                  aoMexerNoMapa!();
                }
              },
      ),
      children: [
        _camadaFundo(escuro),
        if (mostrarPerigos) ..._camadasPerigo(context),
        ...camadasExtras,
        const _CamadaUsuario(),
        const Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.all(4),
            child: _Atribuicao(),
          ),
        ),
      ],
    );
  }

  Widget _camadaFundo(bool escuro) {
    if (Config.temChaveCarto) {
      // CARTO Voyager / Dark Matter: visual limpo, parecido com o Waze.
      final estilo = escuro ? 'dark_all' : 'voyager';
      return TileLayer(
        urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/$estilo/'
            '{z}/{x}/{y}.png?key=${Config.cartoApiKey}',
        userAgentPackageName: 'br.unit.enchentealerta.enchente_alerta',
        // Sem internet o mapa só fica sem imagem, sem quebrar a tela.
        errorTileCallback: (tile, error, stackTrace) {},
      );
    }
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'br.unit.enchentealerta.enchente_alerta',
      // No modo noturno, escurece o mapa do OpenStreetMap.
      tileBuilder: escuro ? darkModeTileBuilder : null,
      errorTileCallback: (tile, error, stackTrace) {},
    );
  }

  List<Widget> _camadasPerigo(BuildContext context) {
    final lista = PerigosService.instance.perigos;
    return [
      ValueListenableBuilder<List<Perigo>>(
        valueListenable: lista,
        builder: (context, perigos, _) => PolygonLayer(
          polygons: [
            for (final p in perigos)
              if (p.raioMetros == null)
                Polygon(
                  points: p.poligono,
                  color: _cor(p).withValues(alpha: 0.22),
                  borderColor: _cor(p),
                  borderStrokeWidth: 2,
                ),
          ],
        ),
      ),
      ValueListenableBuilder<List<Perigo>>(
        valueListenable: lista,
        builder: (context, perigos, _) => CircleLayer(
          circles: [
            for (final p in perigos)
              if (p.raioMetros case final raio?)
                CircleMarker(
                  point: p.centro,
                  radius: raio,
                  useRadiusInMeter: true,
                  color: _cor(p).withValues(alpha: 0.22),
                  borderColor: _cor(p),
                  borderStrokeWidth: 2,
                ),
          ],
        ),
      ),
      ValueListenableBuilder<List<Perigo>>(
        valueListenable: lista,
        builder: (context, perigos, _) => MarkerLayer(
          rotate: true,
          markers: [
            for (final p in perigos)
              Marker(
                point: p.centro,
                width: 40,
                height: 40,
                child: _IconePerigo(
                  perigo: p,
                  aoTocar: () => mostrarDetalhesPerigo(context, p),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

/// Vermelho = as rotas desviam; laranja = aviso ainda não confirmado.
Color _cor(Perigo p) => p.bloqueia ? AppColors.perigo : AppColors.alerta;

IconData iconeDoPerigo(Perigo p) {
  if (!p.daComunidade) return Icons.warning_rounded;
  return p.ocorrencia?.tipo == TipoOcorrencia.viaObstruida
      ? Icons.block
      : Icons.water_drop;
}

class _IconePerigo extends StatelessWidget {
  const _IconePerigo({required this.perigo, required this.aoTocar});

  final Perigo perigo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${perigo.titulo}: ${perigo.detalhe}',
      child: GestureDetector(
        onTap: aoTocar,
        child: Container(
          decoration: BoxDecoration(
            color: _cor(perigo),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
          ),
          child: Icon(iconeDoPerigo(perigo), color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Seta azul do usuário (aponta para onde ele está indo).
class _CamadaUsuario extends StatelessWidget {
  const _CamadaUsuario();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PosicaoUsuario?>(
      valueListenable: LocalizacaoService.instance.posicao,
      builder: (context, posicao, _) {
        if (posicao == null) return const SizedBox.shrink();
        return MarkerLayer(
          markers: [
            Marker(
              point: posicao.ponto,
              width: 44,
              height: 44,
              child: MarcadorUsuario(rumo: posicao.rumo),
            ),
          ],
        );
      },
    );
  }
}

class MarcadorUsuario extends StatelessWidget {
  const MarcadorUsuario({super.key, this.rumo});

  /// Graus em relação ao norte. Null = parado (mostra só o ponto).
  final double? rumo;

  static const azul = Color(0xFF2F7BF5);

  @override
  Widget build(BuildContext context) {
    final rumo = this.rumo;
    return Semantics(
      label: 'Você está aqui',
      child: Container(
        decoration: BoxDecoration(
          color: azul,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
        ),
        child: rumo == null
            ? null
            : Transform.rotate(
                // O ícone já aponta para cima (norte).
                angle: rumo * math.pi / 180,
                child: const Icon(Icons.navigation, color: Colors.white),
              ),
      ),
    );
  }
}

class _Atribuicao extends StatelessWidget {
  const _Atribuicao();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: const Color(0xCCFFFFFF),
      child: Text(
        Config.temChaveCarto
            ? '© OpenStreetMap © CARTO'
            : '© OpenStreetMap contributors',
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      ),
    );
  }
}
