import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversores.dart';

/// Subcoleção `usuarios/{uid}/notificacoes/{notificacaoId}`.
class Notificacao {
  final String id;
  final String mensagem;
  final String? alertaId;
  final DateTime enviadaEm;
  final bool lida;

  const Notificacao({
    required this.id,
    required this.mensagem,
    this.alertaId,
    required this.enviadaEm,
    this.lida = false,
  });

  factory Notificacao.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      Notificacao.fromMap(doc.id, doc.data()!);

  factory Notificacao.fromMap(String id, Map<String, dynamic> d) => Notificacao(
        id: id,
        mensagem: d['mensagem'] as String,
        alertaId: d['alertaId'] as String?,
        enviadaEm: lerData(d['enviadaEm']),
        lida: d['lida'] as bool? ?? false,
      );

  Map<String, dynamic> toFirestore() => {
        'mensagem': mensagem,
        if (alertaId != null) 'alertaId': alertaId,
        'enviadaEm': Timestamp.fromDate(enviadaEm),
        'lida': lida,
      };
}
