import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Funções de apoio para ler e gravar os tipos do Firestore (resumo de tipos
/// em docs/modelagem-firestore.md, seção 4).

/// Timestamp do Firestore -> DateTime.
DateTime lerData(Object? valor) {
  if (valor is Timestamp) return valor.toDate();
  if (valor is DateTime) return valor;
  throw FormatException('Data inválida: $valor');
}

/// Timestamp opcional -> DateTime ou null.
DateTime? lerDataOpcional(Object? valor) => valor == null ? null : lerData(valor);

/// number do Firestore -> int (o Firestore pode devolver 10.0 em vez de 10).
int lerInt(Object? valor) => (valor as num).toInt();

/// number do Firestore -> double.
double lerDouble(Object? valor) => (valor as num).toDouble();

/// GeoPoint -> LatLng (tipo usado pelo flutter_map).
LatLng lerPonto(Object? valor) {
  final ponto = valor as GeoPoint;
  return LatLng(ponto.latitude, ponto.longitude);
}

/// LatLng -> GeoPoint.
GeoPoint gravarPonto(LatLng ponto) => GeoPoint(ponto.latitude, ponto.longitude);

/// array de GeoPoint -> `List<LatLng>`.
List<LatLng> lerPontos(Object? valor) =>
    (valor as List? ?? const []).map(lerPonto).toList();

/// `List<LatLng>` -> array de GeoPoint.
List<GeoPoint> gravarPontos(List<LatLng> pontos) =>
    pontos.map(gravarPonto).toList();

/// array de string -> `List<String>`.
List<String> lerIds(Object? valor) =>
    (valor as List? ?? const []).cast<String>().toList();
