import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversores.dart';
import 'enums.dart';

/// Coleção `guias/{guiaId}`: orientações do Guia de preparação.
class GuiaOrientacao {
  final String id;
  final String titulo;
  final String conteudo;
  final FaseGuia fase;
  final int ordem;

  const GuiaOrientacao({
    required this.id,
    required this.titulo,
    required this.conteudo,
    required this.fase,
    this.ordem = 0,
  });

  /// Orientações de uma fase, na ordem de exibição.
  static List<GuiaOrientacao> filtrarPorFase(
    List<GuiaOrientacao> guias,
    FaseGuia fase,
  ) =>
      guias.where((g) => g.fase == fase).toList()
        ..sort((a, b) => a.ordem.compareTo(b.ordem));

  factory GuiaOrientacao.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      GuiaOrientacao.fromMap(doc.id, doc.data()!);

  factory GuiaOrientacao.fromMap(String id, Map<String, dynamic> d) =>
      GuiaOrientacao(
        id: id,
        titulo: d['titulo'] as String,
        conteudo: d['conteudo'] as String,
        fase: enumPorCodigo(FaseGuia.values, d['fase']),
        ordem: d['ordem'] == null ? 0 : lerInt(d['ordem']),
      );

  Map<String, dynamic> toFirestore() => {
        'titulo': titulo,
        'conteudo': conteudo,
        'fase': fase.codigo,
        'ordem': ordem,
      };
}
