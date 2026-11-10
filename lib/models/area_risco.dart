import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'conversores.dart';
import 'enums.dart';

/// Coleção `areasRisco/{areaRiscoId}`.
class AreaRisco {
  final String id;
  final String nome;
  final Gravidade nivelAtual;
  final List<LatLng> poligono;

  const AreaRisco({
    required this.id,
    required this.nome,
    required this.nivelAtual,
    required this.poligono,
  });

  /// Verifica se o ponto está dentro do polígono (algoritmo do raio:
  /// conta quantas vezes uma linha horizontal a partir do ponto cruza as
  /// bordas; número ímpar = dentro).
  bool contem(LatLng ponto) {
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

  factory AreaRisco.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AreaRisco.fromMap(doc.id, doc.data()!);

  factory AreaRisco.fromMap(String id, Map<String, dynamic> d) => AreaRisco(
        id: id,
        nome: d['nome'] as String,
        nivelAtual: enumPorCodigo(Gravidade.values, d['nivelAtual']),
        poligono: lerPontos(d['poligono']),
      );

  Map<String, dynamic> toFirestore() => {
        'nome': nome,
        'nivelAtual': nivelAtual.codigo,
        'poligono': gravarPontos(poligono),
      };
}
