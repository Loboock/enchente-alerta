import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'erro_servico.dart';

/// Denúncias de um mesmo aviso, juntas para a Defesa Civil decidir de uma
/// vez.
class GrupoDenuncias {
  const GrupoDenuncias({required this.ocorrenciaId, required this.denuncias});

  final String ocorrenciaId;

  /// Da mais recente para a mais antiga.
  final List<Denuncia> denuncias;

  DateTime get ultima => denuncias.first.criadaEm;
}

/// Ações exclusivas da Defesa Civil sobre os avisos da comunidade:
/// revisar denúncias, resolver avisos e excluir os falsos.
///
/// As denúncias ficam em `ocorrencias/{id}/denuncias/{uid}`. Para ver todas
/// numa lista só, a consulta é de grupo de coleções (`collectionGroup`),
/// liberada pelas regras só para a Defesa Civil.
class DefesaCivilService {
  DefesaCivilService();

  /// Trocável nos testes por uma versão falsa.
  static DefesaCivilService instance = DefesaCivilService();

  /// Denúncias pendentes agrupadas por aviso, as mais recentes primeiro.
  final pendentes = ValueNotifier<List<GrupoDenuncias>>(const []);

  StreamSubscription<Object?>? _assinatura;

  /// Chamar só com uma conta da Defesa Civil (as regras recusam as outras).
  void iniciar() {
    if (_assinatura != null) return;
    final db = firestoreOuNull();
    if (db == null) return;
    _assinatura = db.collectionGroup('denuncias').snapshots().listen(
      (snap) {
        final porAviso = <String, List<Denuncia>>{};
        for (final doc in snap.docs) {
          final avisoId = doc.reference.parent.parent?.id;
          if (avisoId == null) continue;
          try {
            porAviso.putIfAbsent(avisoId, () => []).add(
                  Denuncia.fromFirestore(doc),
                );
          } catch (e) {
            debugPrint('Denúncia ignorada: $e');
          }
        }
        pendentes.value = agrupar(porAviso);
      },
      onError: (Object e) => debugPrint('denuncias: $e'),
    );
  }

  /// Ordena cada grupo e os grupos (mais recente primeiro).
  static List<GrupoDenuncias> agrupar(Map<String, List<Denuncia>> porAviso) {
    final grupos = [
      for (final MapEntry(:key, :value) in porAviso.entries)
        GrupoDenuncias(
          ocorrenciaId: key,
          denuncias: List.of(value)
            ..sort((a, b) => b.criadaEm.compareTo(a.criadaEm)),
        ),
    ]..sort((a, b) => b.ultima.compareTo(a.ultima));
    return grupos;
  }

  DocumentReference<Map<String, dynamic>> _aviso(
          FirebaseFirestore db, String id) =>
      db.collection('ocorrencias').doc(id);

  void _apagarDenuncias(
    WriteBatch lote,
    FirebaseFirestore db,
    String avisoId,
    List<Denuncia> denuncias,
  ) {
    for (final d in denuncias) {
      lote.delete(_aviso(db, avisoId).collection('denuncias').doc(d.id));
    }
  }

  /// A água baixou: o aviso vira RESOLVIDA (sai do mapa e das rotas, mas
  /// fica guardado para o histórico) e as denúncias dele são arquivadas.
  Future<void> resolverAviso(
    String avisoId, {
    List<Denuncia> denuncias = const [],
  }) async {
    final db = firestoreObrigatorio();
    final lote = db.batch()
      ..update(_aviso(db, avisoId),
          {'status': StatusOcorrencia.resolvida.codigo});
    _apagarDenuncias(lote, db, avisoId, denuncias);
    await gravarNoFirestore(lote.commit);
  }

  /// O aviso está certo: apaga as denúncias e ele continua no mapa.
  Future<void> manterAviso(String avisoId, List<Denuncia> denuncias) async {
    final db = firestoreObrigatorio();
    final lote = db.batch();
    _apagarDenuncias(lote, db, avisoId, denuncias);
    await gravarNoFirestore(lote.commit);
  }

  /// Aviso falso ou abusivo: exclui o aviso, o autor e as denúncias.
  Future<void> excluirAviso(String avisoId, List<Denuncia> denuncias) async {
    final db = firestoreObrigatorio();
    final lote = db.batch()
      ..delete(_aviso(db, avisoId))
      ..delete(db.collection('autoresOcorrencias').doc(avisoId));
    _apagarDenuncias(lote, db, avisoId, denuncias);
    await gravarNoFirestore(lote.commit);
  }

  void parar() {
    _assinatura?.cancel();
    _assinatura = null;
    pendentes.value = const [];
  }
}
