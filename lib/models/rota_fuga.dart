import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'conversores.dart';
import 'enums.dart';

/// Coleção `rotasFuga/{rotaId}`. Cada rota leva a um abrigo.
/// Só a Defesa Civil cria, edita e exclui.
class RotaFuga {
  final String id;
  final String abrigoId;
  final List<LatLng> pontos;
  final int distanciaMetros;
  final int tempoAPeMin;
  final int tempoCarroMin;
  final Gravidade riscoNaVia;
  final bool interditada;
  final List<String> areasEvitadasIds;
  final String? atualizadoPor;

  const RotaFuga({
    required this.id,
    required this.abrigoId,
    required this.pontos,
    required this.distanciaMetros,
    required this.tempoAPeMin,
    required this.tempoCarroMin,
    this.riscoNaVia = Gravidade.leve,
    this.interditada = false,
    this.areasEvitadasIds = const [],
    this.atualizadoPor,
  });

  bool get estaLiberada => !interditada;

  factory RotaFuga.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      RotaFuga.fromMap(doc.id, doc.data()!);

  factory RotaFuga.fromMap(String id, Map<String, dynamic> d) => RotaFuga(
        id: id,
        abrigoId: d['abrigoId'] as String,
        pontos: lerPontos(d['pontos']),
        distanciaMetros: lerInt(d['distanciaMetros']),
        tempoAPeMin: lerInt(d['tempoAPeMin']),
        tempoCarroMin: lerInt(d['tempoCarroMin']),
        riscoNaVia: enumPorCodigo(Gravidade.values, d['riscoNaVia']),
        interditada: d['interditada'] as bool? ?? false,
        areasEvitadasIds: lerIds(d['areasEvitadasIds']),
        atualizadoPor: d['atualizadoPor'] as String?,
      );

  Map<String, dynamic> toFirestore() => {
        'abrigoId': abrigoId,
        'pontos': gravarPontos(pontos),
        'distanciaMetros': distanciaMetros,
        'tempoAPeMin': tempoAPeMin,
        'tempoCarroMin': tempoCarroMin,
        'riscoNaVia': riscoNaVia.codigo,
        'interditada': interditada,
        'areasEvitadasIds': areasEvitadasIds,
        if (atualizadoPor != null) 'atualizadoPor': atualizadoPor,
      };
}
