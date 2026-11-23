import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/dados_provisorios.dart';
import '../models/models.dart';
import 'erro_servico.dart';

/// Orientações do Guia de segurança (`guias`), em tempo real (RF06, RF09).
///
/// Enquanto a Defesa Civil não publicar nenhuma, o app mostra o guia de
/// exemplo que vem com ele, para o Guia nunca ficar vazio (nem offline).
class GuiasService {
  GuiasService();

  /// Trocável nos testes por uma versão falsa.
  static GuiasService instance = GuiasService();

  /// Orientações publicadas no Firestore.
  final publicadas = ValueNotifier<List<GuiaOrientacao>>(const []);

  /// O que o Guia mostra: as publicadas ou, sem nenhuma, as de exemplo.
  List<GuiaOrientacao> get paraMoradores =>
      publicadas.value.isEmpty ? guiasProvisorios : publicadas.value;

  bool get usandoExemplos => publicadas.value.isEmpty;

  StreamSubscription<Object?>? _assinatura;

  void iniciar() {
    if (_assinatura != null) return;
    final db = firestoreOuNull();
    if (db == null) return;
    _assinatura = db.collection('guias').snapshots().listen(
      (snap) {
        final lista = <GuiaOrientacao>[];
        for (final doc in snap.docs) {
          try {
            lista.add(GuiaOrientacao.fromFirestore(doc));
          } catch (e) {
            debugPrint('Orientação ignorada: $e');
          }
        }
        lista.sort((a, b) {
          final f = a.fase.index.compareTo(b.fase.index);
          return f != 0 ? f : a.ordem.compareTo(b.ordem);
        });
        publicadas.value = lista;
      },
      onError: (Object e) => debugPrint('guias: $e'),
    );
  }

  Future<void> salvar(GuiaOrientacao g) async {
    final col = firestoreObrigatorio().collection('guias');
    final ref = g.id.isEmpty ? col.doc() : col.doc(g.id);
    await gravarNoFirestore(() => ref.set(g.toFirestore()));
  }

  Future<void> excluir(GuiaOrientacao g) async {
    final ref = firestoreObrigatorio().collection('guias').doc(g.id);
    await gravarNoFirestore(ref.delete);
  }

  /// Publica o guia de exemplo de uma vez, para a Defesa Civil editar.
  Future<void> publicarExemplos() async {
    final db = firestoreObrigatorio();
    final lote = db.batch();
    for (final g in guiasProvisorios) {
      lote.set(db.collection('guias').doc(), g.toFirestore());
    }
    await gravarNoFirestore(lote.commit);
  }
}
