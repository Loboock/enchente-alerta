import '../models/models.dart';
import 'erro_servico.dart';

/// Cadastro das áreas de risco (`areasRisco`) pela Defesa Civil.
///
/// A leitura em tempo real já é feita pelo PerigosService (o mapa e as
/// rotas usam as áreas); aqui ficam só as gravações.
class AreasRiscoService {
  AreasRiscoService();

  /// Trocável nos testes por uma versão falsa.
  static AreasRiscoService instance = AreasRiscoService();

  /// Cria (id vazio) ou altera uma área.
  Future<void> salvar(AreaRisco area) async {
    if (area.poligono.length < 3) {
      throw ServicoException('Marque pelo menos 3 pontos no mapa.');
    }
    final col = firestoreObrigatorio().collection('areasRisco');
    final ref = area.id.isEmpty ? col.doc() : col.doc(area.id);
    await gravarNoFirestore(() => ref.set(area.toFirestore()));
  }

  Future<void> excluir(AreaRisco area) async {
    final ref = firestoreObrigatorio().collection('areasRisco').doc(area.id);
    await gravarNoFirestore(ref.delete);
  }
}
