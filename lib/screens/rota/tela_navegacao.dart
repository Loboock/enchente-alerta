import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/destino.dart';
import '../../models/rota_calculada.dart';
import '../../services/localizacao_service.dart';
import '../../services/perigos_service.dart';
import '../../services/rotas_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatacao.dart';
import '../../utils/geo.dart';
import '../../widgets/mapa/botao_mapa.dart';
import '../../widgets/mapa/folha_reportar.dart';
import '../../widgets/mapa/icones_manobra.dart';
import '../../widgets/mapa/mapa_enchente.dart';
import 'tela_rota_fuga.dart';

/// Navegação curva a curva, no estilo do Waze: o mapa segue e gira com a
/// pessoa, o topo mostra a próxima manobra e a rota é recalculada se ela
/// sair do caminho ou se um alagamento for confirmado à frente.
class TelaNavegacao extends StatefulWidget {
  const TelaNavegacao({super.key, required this.destino, required this.rota});

  final Destino destino;
  final RotaCalculada rota;

  @override
  State<TelaNavegacao> createState() => _TelaNavegacaoState();
}

class _TelaNavegacaoState extends State<TelaNavegacao> {
  static const _zoomNavegacao = 17.5;

  /// Distância até a linha para considerar que saiu da rota.
  static const _foraDaRotaCarro = 45.0;
  static const _foraDaRotaAPe = 30.0;

  /// Intervalo mínimo entre recálculos por ter saído da rota (economiza a
  /// cota diária do OpenRouteService).
  static const _intervaloRecalculo = Duration(seconds: 15);

  final _controle = MapController();
  final _localizacao = LocalizacaoService.instance;
  final _perigos = PerigosService.instance.perigos;

  late RotaCalculada _rota = widget.rota;
  ProjecaoNaRota? _projecao;
  int _segmento = 0;
  int _leiturasForaDaRota = 0;
  DateTime _ultimoRecalculo = DateTime.fromMillisecondsSinceEpoch(0);
  bool _recalculando = false;
  bool _mapaPronto = false;
  bool _seguir = true;
  bool _chegou = false;
  String? _alerta;

  @override
  void initState() {
    super.initState();
    _localizacao.posicao.addListener(_aoMover);
    _perigos.addListener(_aoMudarPerigos);
  }

  @override
  void dispose() {
    _localizacao.posicao.removeListener(_aoMover);
    _perigos.removeListener(_aoMudarPerigos);
    _controle.dispose();
    super.dispose();
  }

  void _aoMover() {
    if (!mounted) return;
    final posicao = _localizacao.posicao.value;
    if (posicao == null || _chegou) return;

    // Procura um pouco para trás também (o GPS oscila).
    final projecao = projetarNaRota(
      _rota.pontos,
      posicao.ponto,
      aPartirDe: math.max(0, _segmento - 5),
    );
    final limite = _rota.modo == ModoTransporte.carro
        ? _foraDaRotaCarro
        : _foraDaRotaAPe;
    final precisao = posicao.precisaoMetros ?? 0;

    if (projecao.distanciaMetros > limite + precisao) {
      _leiturasForaDaRota++;
      // 3 leituras seguidas: não é só o GPS pulando.
      if (_leiturasForaDaRota >= 3) {
        _recalcular('Você saiu da rota. Recalculando...');
      }
    } else {
      _leiturasForaDaRota = 0;
    }

    final faltam = _rota.distanciaMetros - _rota.percorrido(projecao);
    final chegou = metrosEntre(posicao.ponto, widget.destino.posicao) < 30 ||
        (projecao.distanciaMetros < limite && faltam < 20);

    setState(() {
      _projecao = projecao;
      _segmento = projecao.segmento;
      _chegou = chegou;
    });
    _moverCamera(posicao);
  }

  void _moverCamera(PosicaoUsuario posicao) {
    if (!_mapaPronto || !_seguir) return;
    final rumo = posicao.rumo;
    if (rumo != null) {
      // Gira o mapa para a direção do movimento ficar para cima.
      _controle.moveAndRotate(posicao.ponto, _zoomNavegacao, -rumo);
    } else {
      _controle.move(posicao.ponto, _zoomNavegacao);
    }
  }

  void _aoMudarPerigos() {
    final aFrente = _perigos.value.where(
      (p) =>
          p.bloqueia &&
          !_rota.perigosInevitaveis.any((x) => x.id == p.id) &&
          p.cruza(_rota.pontos, aPartirDe: _segmento),
    );
    if (aFrente.isEmpty) return;
    _recalcular(
      '${aFrente.first.titulo} confirmado à frente. Recalculando...',
      urgente: true,
    );
  }

  Future<void> _recalcular(String motivo, {bool urgente = false}) async {
    if (_recalculando) return;
    final agora = DateTime.now();
    if (!urgente && agora.difference(_ultimoRecalculo) < _intervaloRecalculo) {
      return;
    }
    _recalculando = true;
    _ultimoRecalculo = agora;
    setState(() => _alerta = motivo);

    try {
      final origem = _localizacao.posicao.value?.ponto ?? _rota.pontos.first;
      final nova = await RotasService.instance.calcular(
        origem: origem,
        destino: widget.destino.posicao,
        modo: _rota.modo,
        perigos: _perigos.value,
      );
      if (!mounted) return;
      setState(() {
        _rota = nova;
        _segmento = 0;
        _leiturasForaDaRota = 0;
        _projecao = null;
        _alerta = null;
      });
      _aoMover();
    } on RotaException catch (e) {
      if (mounted) setState(() => _alerta = e.mensagem);
    } finally {
      _recalculando = false;
    }
  }

  void _recentralizar() {
    setState(() => _seguir = true);
    final posicao = _localizacao.posicao.value;
    if (posicao != null) _moverCamera(posicao);
  }

  void _encerrar() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final rota = _rota;
    final projecao = _projecao;
    final percorrido = projecao == null ? 0.0 : rota.percorrido(projecao);
    final faltamMetros = math.max(0.0, rota.distanciaMetros - percorrido);
    final faltamSeg = rota.distanciaMetros <= 0
        ? 0.0
        : rota.duracaoSeg * faltamMetros / rota.distanciaMetros;

    // Linha: trecho feito em cinza, trecho que falta em azul.
    final List<LatLng> feito;
    final List<LatLng> falta;
    if (projecao == null) {
      feito = const [];
      falta = rota.pontos;
    } else {
      final i = projecao.segmento;
      feito = [...rota.pontos.take(i + 1), projecao.ponto];
      falta = [projecao.ponto, ...rota.pontos.skip(i + 1)];
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          MapaEnchente(
            controller: _controle,
            centroInicial: _localizacao.posicao.value?.ponto ??
                (rota.pontos.isEmpty ? widget.destino.posicao : rota.pontos.first),
            zoomInicial: _zoomNavegacao,
            aoFicarPronto: () {
              _mapaPronto = true;
              _aoMover();
            },
            aoMexerNoMapa: () {
              if (_seguir) setState(() => _seguir = false);
            },
            camadasExtras: [
              PolylineLayer(
                polylines: [
                  if (feito.length >= 2)
                    Polyline(
                      points: feito,
                      strokeWidth: 8,
                      color: Colors.grey.shade500,
                    ),
                  if (falta.length >= 2) linhaRota(falta),
                ],
              ),
              MarkerLayer(markers: [pinoDestino(widget.destino.posicao)]),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  _BannerManobra(
                    rota: rota,
                    percorrido: percorrido,
                    segmento: projecao?.segmento ?? 0,
                    faltamMetros: faltamMetros,
                  ),
                  if (_alerta case final alerta?) _BannerAlerta(texto: alerta),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 140,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_seguir) ...[
                    BotaoMapa(
                      icone: Icons.navigation,
                      dica: 'Voltar a seguir minha posição',
                      aoTocar: _recentralizar,
                    ),
                    const SizedBox(height: 12),
                  ],
                  BotaoMapa(
                    icone: Icons.campaign,
                    dica: 'Reportar alagamento',
                    cor: AppColors.alerta,
                    corIcone: AppColors.azulMarinho,
                    tamanho: 60,
                    aoTocar: () => mostrarReportar(context),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _chegou
                ? _PainelChegada(destino: widget.destino, aoEncerrar: _encerrar)
                : _PainelInferior(
                    faltamSeg: faltamSeg,
                    faltamMetros: faltamMetros,
                    aoEncerrar: _encerrar,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Topo azul-escuro: ícone da próxima manobra, distância até ela e texto.
class _BannerManobra extends StatelessWidget {
  const _BannerManobra({
    required this.rota,
    required this.percorrido,
    required this.segmento,
    required this.faltamMetros,
  });

  final RotaCalculada rota;
  final double percorrido;
  final int segmento;
  final double faltamMetros;

  @override
  Widget build(BuildContext context) {
    final passos = rota.passos;
    IconData icone = Icons.flag;
    String texto = 'Siga até o destino';
    String? via;
    double distancia = faltamMetros;

    if (passos.isNotEmpty) {
      final atual = rota.passoNoSegmento(segmento);
      if (atual + 1 < passos.length) {
        // A instrução do PRÓXIMO passo é a manobra no fim do passo atual.
        final proximo = passos[atual + 1];
        final fim = math.min(passos[atual].fim, rota.acumulado.length - 1);
        distancia = math.max(0.0, rota.acumulado[fim] - percorrido);
        icone = iconeManobra(proximo.tipo);
        texto = proximo.instrucao;
        via = proximo.via.isEmpty ? null : proximo.via;
      } else {
        icone = iconeManobra(PassoRota.tipoChegada);
        texto = 'Chegando ao destino';
      }
    }

    return Material(
      color: AppColors.azulMarinho,
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Semantics(
          liveRegion: true,
          label: 'Em ${formatarDistancia(distancia)}, $texto',
          child: ExcludeSemantics(
            child: Row(
              children: [
                Icon(icone, color: Colors.white, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatarDistancia(distancia),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        via ?? texto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (via != null)
                        Text(
                          texto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.azulClaro,
                            fontSize: 13,
                          ),
                        ),
                    ],
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

class _BannerAlerta extends StatelessWidget {
  const _BannerAlerta({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.alerta,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.azulMarinho),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(
                  color: AppColors.azulMarinho,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rodapé: hora de chegada, tempo e distância que faltam, botão de sair.
class _PainelInferior extends StatelessWidget {
  const _PainelInferior({
    required this.faltamSeg,
    required this.faltamMetros,
    required this.aoEncerrar,
  });

  final double faltamSeg;
  final double faltamMetros;
  final VoidCallback aoEncerrar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final minutos = math.max(1, (faltamSeg / 60).round());

    return Material(
      color: cores.surface,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 20, 14),
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Encerrar navegação',
                iconSize: 28,
                onPressed: aoEncerrar,
                icon: const Icon(Icons.close),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chegada ${horaDeChegada(faltamSeg)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cores.onSurface,
                      ),
                    ),
                    Text(
                      '$minutos min · ${formatarDistancia(faltamMetros)}',
                      style: TextStyle(
                        fontSize: 15,
                        color: cores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PainelChegada extends StatelessWidget {
  const _PainelChegada({required this.destino, required this.aoEncerrar});

  final Destino destino;
  final VoidCallback aoEncerrar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Material(
      color: cores.surface,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, color: AppColors.seguro, size: 48),
              const SizedBox(height: 8),
              Text(
                'Você chegou em ${destino.nome}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: aoEncerrar,
                child: const Text('Encerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
