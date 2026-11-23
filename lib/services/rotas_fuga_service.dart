import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import 'auth_service.dart';
import 'erro_servico.dart';

/// Rotas de fuga traçadas pela Defesa Civil (`rotasFuga`), em tempo real.
///
/// Complementam as rotas calculadas na hora (OpenRouteService): são os
/// caminhos oficiais até os abrigos, que todos veem no mapa e que continuam
/// visíveis sem internet (o Firestore guarda no aparelho).
class RotasFugaService {
  RotasFugaService();

  /// Trocável nos testes por uma versão falsa.
  static RotasFugaService instance = RotasFugaService();

  /// Velocidades usadas para estimar o tempo (a pé ~4,7 km/h; carro em
  /// rua alagável ~30 km/h).
  static const _metrosPorMinAPe = 78.0;
  static const _metrosPorMinCarro = 500.0;

  final rotas = ValueNotifier<List<RotaFuga>>(const []);

  StreamSubscription<Object?>? _assinatura;

  void iniciar() {
    if (_assinatura != null) return;
    final db = firestoreOuNull();
    if (db == null) return;
    _assinatura = db.collection('rotasFuga').snapshots().listen(
      (snap) {
        final lista = <RotaFuga>[];
        for (final doc in snap.docs) {
          try {
            lista.add(RotaFuga.fromFirestore(doc));
          } catch (e) {
            debugPrint('Rota ignorada: $e');
          }
        }
        rotas.value = lista;
      },
      onError: (Object e) => debugPrint('rotasFuga: $e'),
    );
  }

  /// Distância total do traçado, em metros.
  static int distancia(List<LatLng> pontos) {
    const d = Distance();
    var total = 0.0;
    for (var i = 1; i < pontos.length; i++) {
      total += d.as(LengthUnit.Meter, pontos[i - 1], pontos[i]);
    }
    return total.round();
  }

  /// Monta a rota com distância e tempos calculados a partir dos pontos.
  static RotaFuga montar({
    required String id,
    required String abrigoId,
    required List<LatLng> pontos,
    required Gravidade riscoNaVia,
    required bool interditada,
  }) {
    final metros = distancia(pontos);
    return RotaFuga(
      id: id,
      abrigoId: abrigoId,
      pontos: pontos,
      distanciaMetros: metros,
      tempoAPeMin: (metros / _metrosPorMinAPe).ceil(),
      tempoCarroMin: (metros / _metrosPorMinCarro).ceil(),
      riscoNaVia: riscoNaVia,
      interditada: interditada,
      atualizadoPor: AuthService.instance.user?.uid,
    );
  }

  Future<void> salvar(RotaFuga rota) async {
    if (rota.pontos.length < 2) {
      throw ServicoException('Marque o caminho com pelo menos 2 pontos.');
    }
    final col = firestoreObrigatorio().collection('rotasFuga');
    final ref = rota.id.isEmpty ? col.doc() : col.doc(rota.id);
    await gravarNoFirestore(() => ref.set(rota.toFirestore()));
  }

  Future<void> alterarInterdicao(RotaFuga rota, bool interditada) async {
    final ref = firestoreObrigatorio().collection('rotasFuga').doc(rota.id);
    await gravarNoFirestore(() => ref.update({'interditada': interditada}));
  }

  Future<void> excluir(RotaFuga rota) async {
    final ref = firestoreObrigatorio().collection('rotasFuga').doc(rota.id);
    await gravarNoFirestore(ref.delete);
  }
}
