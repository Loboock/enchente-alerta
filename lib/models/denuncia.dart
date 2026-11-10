import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversores.dart';
import 'enums.dart';

/// Subcoleção `ocorrencias/{ocorrenciaId}/denuncias/{denunciaId}`
/// (tela "Reportar aviso"). Só a Defesa Civil lê.
class Denuncia {
  final String id;
  final String autorId;
  final MotivoDenuncia motivo;
  final String? detalhes;
  final DateTime criadaEm;

  const Denuncia({
    required this.id,
    required this.autorId,
    required this.motivo,
    this.detalhes,
    required this.criadaEm,
  });

  factory Denuncia.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Denuncia.fromMap(doc.id, doc.data()!);

  factory Denuncia.fromMap(String id, Map<String, dynamic> d) => Denuncia(
        id: id,
        autorId: d['autorId'] as String,
        motivo: enumPorCodigo(MotivoDenuncia.values, d['motivo']),
        detalhes: d['detalhes'] as String?,
        criadaEm: lerData(d['criadaEm']),
      );

  Map<String, dynamic> toFirestore() => {
        'autorId': autorId,
        'motivo': motivo.codigo,
        if (detalhes != null) 'detalhes': detalhes,
        'criadaEm': Timestamp.fromDate(criadaEm),
      };
}
