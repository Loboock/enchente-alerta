import 'package:latlong2/latlong.dart';

import 'abrigo.dart';

/// Ponto para onde a rota de fuga leva (abrigo, local salvo ou endereço).
///
/// É um conceito só das telas de rota: não vai para o Firestore e por isso
/// não está em `models.dart`.
class Destino {
  const Destino({required this.nome, required this.posicao, this.abrigoId});

  final String nome;
  final LatLng posicao;

  /// Preenchido quando o destino é um abrigo.
  final String? abrigoId;
}

extension AbrigoComoDestino on Abrigo {
  Destino get comoDestino =>
      Destino(nome: nome, posicao: localizacao, abrigoId: id);
}
