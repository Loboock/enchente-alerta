import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversores.dart';
import 'enums.dart';

/// Coleção `alertas/{alertaId}`.
class Alerta {
  final String id;
  final String titulo;
  final String descricao;
  final Gravidade nivel;
  final OrigemAlerta origem;
  final List<String> areasRiscoIds;
  final List<String> ocorrenciasIds;
  final List<String> guiasIds;
  final DateTime emitidoEm;
  final DateTime expiraEm;

  const Alerta({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.nivel,
    required this.origem,
    this.areasRiscoIds = const [],
    this.ocorrenciasIds = const [],
    this.guiasIds = const [],
    required this.emitidoEm,
    required this.expiraEm,
  });

  bool estaAtivo([DateTime? agora]) =>
      expiraEm.isAfter(agora ?? DateTime.now());

  factory Alerta.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Alerta.fromMap(doc.id, doc.data()!);

  factory Alerta.fromMap(String id, Map<String, dynamic> d) => Alerta(
        id: id,
        titulo: d['titulo'] as String,
        descricao: d['descricao'] as String? ?? '',
        nivel: enumPorCodigo(Gravidade.values, d['nivel']),
        origem: enumPorCodigo(OrigemAlerta.values, d['origem']),
        areasRiscoIds: lerIds(d['areasRiscoIds']),
        ocorrenciasIds: lerIds(d['ocorrenciasIds']),
        guiasIds: lerIds(d['guiasIds']),
        emitidoEm: lerData(d['emitidoEm']),
        expiraEm: lerData(d['expiraEm']),
      );

  Map<String, dynamic> toFirestore() => {
        'titulo': titulo,
        'descricao': descricao,
        'nivel': nivel.codigo,
        'origem': origem.codigo,
        'areasRiscoIds': areasRiscoIds,
        'ocorrenciasIds': ocorrenciasIds,
        'guiasIds': guiasIds,
        'emitidoEm': Timestamp.fromDate(emitidoEm),
        'expiraEm': Timestamp.fromDate(expiraEm),
      };
}
