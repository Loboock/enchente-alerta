import '../models/models.dart';

extension SituacaoDoAbrigo on Abrigo {
  /// Texto de lotação mostrado na lista de abrigos.
  String get situacao {
    if (vagasDisponiveis <= 0) return 'lotado';
    if (capacidade > 0 && vagasDisponiveis / capacidade <= 0.1) {
      return 'lotação quase cheia';
    }
    if (vagasDisponiveis == 1) return '1 vaga disponível';
    return '$vagasDisponiveis vagas disponíveis';
  }
}
