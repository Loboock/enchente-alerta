import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Contas de geometria usadas pelo mapa, pelas rotas e pela navegação.
///
/// Para distâncias curtas (dentro de uma cidade) a Terra pode ser tratada
/// como plana em volta do ponto, o que deixa as contas simples e rápidas.

const _calculo = Distance();
const _raioTerra = 6371000.0;

/// Distância em metros entre dois pontos.
double metrosEntre(LatLng a, LatLng b) =>
    _calculo.as(LengthUnit.Meter, a, b).toDouble();

/// Polígono com [lados] lados em volta de [centro] (aproxima um círculo).
List<LatLng> circuloComoPoligono(
  LatLng centro,
  double raioMetros, {
  int lados = 12,
}) =>
    [
      for (var i = 0; i < lados; i++)
        _calculo.offset(centro, raioMetros, 360 * i / lados),
    ];

/// Ponto dentro do polígono? (algoritmo do raio, o mesmo de AreaRisco).
bool pontoNoPoligono(LatLng ponto, List<LatLng> poligono) {
  var dentro = false;
  for (var i = 0, j = poligono.length - 1; i < poligono.length; j = i++) {
    final a = poligono[i];
    final b = poligono[j];
    final cruza = (a.latitude > ponto.latitude) !=
            (b.latitude > ponto.latitude) &&
        ponto.longitude <
            (b.longitude - a.longitude) *
                    (ponto.latitude - a.latitude) /
                    (b.latitude - a.latitude) +
                a.longitude;
    if (cruza) dentro = !dentro;
  }
  return dentro;
}

/// Centro aproximado (média dos vértices) de um polígono.
LatLng centroDe(List<LatLng> pontos) {
  var lat = 0.0;
  var lng = 0.0;
  for (final p in pontos) {
    lat += p.latitude;
    lng += p.longitude;
  }
  return LatLng(lat / pontos.length, lng / pontos.length);
}

/// Onde um ponto cai sobre a linha da rota.
class ProjecaoNaRota {
  const ProjecaoNaRota({
    required this.segmento,
    required this.fracao,
    required this.distanciaMetros,
    required this.ponto,
  });

  /// Índice do segmento (entre os pontos `segmento` e `segmento + 1`).
  final int segmento;

  /// 0 = no início do segmento, 1 = no fim.
  final double fracao;

  /// Distância do ponto original até a rota.
  final double distanciaMetros;

  /// Ponto mais próximo sobre a rota.
  final LatLng ponto;
}

/// Converte para metros num plano centrado em [origem].
math.Point<double> _plano(LatLng p, LatLng origem) {
  final cosLat = math.cos(origem.latitude * math.pi / 180);
  return math.Point(
    (p.longitude - origem.longitude) * math.pi / 180 * _raioTerra * cosLat,
    (p.latitude - origem.latitude) * math.pi / 180 * _raioTerra,
  );
}

/// Ponto do segmento a-b mais perto de p, com a fração e a distância.
({double fracao, double distancia}) _maisPertoNoSegmento(
  LatLng p,
  LatLng a,
  LatLng b,
) {
  final pa = _plano(a, p);
  final pb = _plano(b, p);
  final dx = pb.x - pa.x;
  final dy = pb.y - pa.y;
  final tamanho2 = dx * dx + dy * dy;
  var t = tamanho2 == 0 ? 0.0 : -(pa.x * dx + pa.y * dy) / tamanho2;
  t = t.clamp(0.0, 1.0);
  final x = pa.x + t * dx;
  final y = pa.y + t * dy;
  return (fracao: t, distancia: math.sqrt(x * x + y * y));
}

/// Distância em metros de [p] até o segmento a-b.
double metrosAteSegmento(LatLng p, LatLng a, LatLng b) =>
    _maisPertoNoSegmento(p, a, b).distancia;

/// Acha o ponto da rota mais perto de [p], olhando a partir do segmento
/// [aPartirDe] (na navegação não faz sentido voltar para trechos já feitos).
ProjecaoNaRota projetarNaRota(
  List<LatLng> rota,
  LatLng p, {
  int aPartirDe = 0,
}) {
  if (rota.length < 2) {
    return ProjecaoNaRota(
      segmento: 0,
      fracao: 0,
      distanciaMetros: rota.isEmpty ? double.infinity : metrosEntre(p, rota[0]),
      ponto: rota.isEmpty ? p : rota[0],
    );
  }
  var melhor = (segmento: 0, fracao: 0.0, distancia: double.infinity);
  for (var i = aPartirDe.clamp(0, rota.length - 2); i < rota.length - 1; i++) {
    final r = _maisPertoNoSegmento(p, rota[i], rota[i + 1]);
    if (r.distancia < melhor.distancia) {
      melhor = (segmento: i, fracao: r.fracao, distancia: r.distancia);
    }
  }
  final a = rota[melhor.segmento];
  final b = rota[melhor.segmento + 1];
  return ProjecaoNaRota(
    segmento: melhor.segmento,
    fracao: melhor.fracao,
    distanciaMetros: melhor.distancia,
    ponto: LatLng(
      a.latitude + (b.latitude - a.latitude) * melhor.fracao,
      a.longitude + (b.longitude - a.longitude) * melhor.fracao,
    ),
  );
}

/// Distância acumulada desde o início da rota até cada ponto.
List<double> distanciasAcumuladas(List<LatLng> pontos) {
  final acumulado = List<double>.filled(pontos.length, 0);
  for (var i = 1; i < pontos.length; i++) {
    acumulado[i] = acumulado[i - 1] + metrosEntre(pontos[i - 1], pontos[i]);
  }
  return acumulado;
}
