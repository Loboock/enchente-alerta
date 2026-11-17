import 'package:latlong2/latlong.dart';

import '../utils/geo.dart';
import 'perigo.dart';

/// Meio de transporte usado para calcular a rota.
enum ModoTransporte {
  carro('driving-car', 'De carro'),
  aPe('foot-walking', 'A pé');

  const ModoTransporte(this.perfilOrs, this.rotulo);

  /// Nome do perfil no OpenRouteService.
  final String perfilOrs;
  final String rotulo;
}

/// Uma instrução da navegação ("Vire à direita na Rua X").
///
/// No OpenRouteService a instrução de cada passo descreve a manobra feita
/// no INÍCIO do passo; depois dela se anda [distanciaMetros] até o próximo.
class PassoRota {
  const PassoRota({
    required this.tipo,
    required this.instrucao,
    required this.via,
    required this.distanciaMetros,
    required this.duracaoSeg,
    required this.inicio,
    required this.fim,
  });

  /// Código da manobra (0 esquerda, 1 direita, 6 siga reto, 10 chegada...).
  /// Lista em lib/widgets/mapa/icones_manobra.dart.
  final int tipo;
  final String instrucao;
  final String via;
  final double distanciaMetros;
  final double duracaoSeg;

  /// Índices em [RotaCalculada.pontos] onde o passo começa e termina.
  final int inicio;
  final int fim;

  static const tipoChegada = 10;
}

/// Rota de verdade calculada na hora (não vai para o Firestore).
///
/// Diferente de [RotaFuga], que é uma rota cadastrada pela Defesa Civil.
class RotaCalculada {
  RotaCalculada({
    required this.modo,
    required this.pontos,
    required this.distanciaMetros,
    required this.duracaoSeg,
    required this.passos,
    this.perigosEvitados = const [],
    this.avisosNoCaminho = const [],
    this.perigosInevitaveis = const [],
  }) : acumulado = distanciasAcumuladas(pontos);

  final ModoTransporte modo;
  final List<LatLng> pontos;
  final double distanciaMetros;
  final double duracaoSeg;
  final List<PassoRota> passos;

  /// Perigos que bloqueiam e ficam perto do caminho: a rota desviou deles.
  final List<Perigo> perigosEvitados;

  /// Avisos ainda não confirmados que ficam no caminho (só alerta).
  final List<Perigo> avisosNoCaminho;

  /// Perigos onde a pessoa já está ou para onde ela vai: não dá para
  /// desviar, então a tela avisa.
  final List<Perigo> perigosInevitaveis;

  /// Metros desde o início até cada ponto de [pontos].
  final List<double> acumulado;

  int get duracaoMin {
    final minutos = (duracaoSeg / 60).round();
    return minutos < 1 ? 1 : minutos;
  }

  /// Metros já percorridos quando a pessoa está em [projecao].
  double percorrido(ProjecaoNaRota projecao) {
    final i = projecao.segmento;
    if (i + 1 >= acumulado.length) return acumulado.isEmpty ? 0 : acumulado.last;
    return acumulado[i] + (acumulado[i + 1] - acumulado[i]) * projecao.fracao;
  }

  /// Índice do passo em que a pessoa está, dado o segmento atual.
  int passoNoSegmento(int segmento) {
    for (var i = 0; i < passos.length; i++) {
      if (segmento < passos[i].fim) return i;
    }
    return passos.isEmpty ? 0 : passos.length - 1;
  }
}
