import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'erro_servico.dart';

/// Alertas da Defesa Civil (coleção `alertas`), em tempo real.
///
/// Todo mundo vê os alertas ativos (faixa no Início e na aba Avisos). Só a
/// Defesa Civil emite, edita, encerra e exclui (regras do Firestore).
class AlertasService {
  AlertasService();

  /// Trocável nos testes por uma versão falsa.
  static AlertasService instance = AlertasService();

  /// Todos os alertas, do mais recente ao mais antigo.
  final alertas = ValueNotifier<List<Alerta>>(const []);

  StreamSubscription<Object?>? _assinatura;
  Timer? _relogio;

  /// Ativos agora, do mais grave ao mais leve (e mais recente primeiro).
  List<Alerta> ativos([DateTime? agora]) {
    final momento = agora ?? DateTime.now();
    return alertas.value.where((a) => a.estaAtivo(momento)).toList()
      ..sort((a, b) {
        final porNivel = b.nivel.index.compareTo(a.nivel.index);
        return porNivel != 0 ? porNivel : b.emitidoEm.compareTo(a.emitidoEm);
      });
  }

  void iniciar() {
    if (_assinatura != null) return;
    final db = firestoreOuNull();
    if (db == null) return;
    _assinatura = db.collection('alertas').snapshots().listen(
      (snap) {
        final lista = <Alerta>[];
        for (final doc in snap.docs) {
          try {
            lista.add(Alerta.fromFirestore(doc));
          } catch (e) {
            debugPrint('Alerta ignorado: $e');
          }
        }
        lista.sort((a, b) => b.emitidoEm.compareTo(a.emitidoEm));
        alertas.value = lista;
      },
      onError: (Object e) => debugPrint('alertas: $e'),
    );
    // Alertas vencem com o tempo, sem mudança no banco: avisa as telas.
    _relogio = Timer.periodic(const Duration(minutes: 1), (_) {
      alertas.value = List.of(alertas.value);
    });
  }

  /// Emite (id vazio) ou altera um alerta.
  Future<void> salvar(Alerta alerta) async {
    final db = firestoreObrigatorio();
    final colecao = db.collection('alertas');
    final ref = alerta.id.isEmpty ? colecao.doc() : colecao.doc(alerta.id);
    await gravarNoFirestore(() => ref.set(alerta.toFirestore()));
  }

  /// Encerra antes do prazo: o alerta sai da tela dos moradores, mas fica
  /// na lista da Defesa Civil.
  Future<void> encerrar(Alerta alerta) async {
    final db = firestoreObrigatorio();
    var fim = DateTime.now();
    // A regra exige expiraEm depois de emitidoEm.
    if (!fim.isAfter(alerta.emitidoEm)) {
      fim = alerta.emitidoEm.add(const Duration(seconds: 1));
    }
    await gravarNoFirestore(() => db
        .collection('alertas')
        .doc(alerta.id)
        .update({'expiraEm': Timestamp.fromDate(fim)}));
  }

  Future<void> excluir(Alerta alerta) async {
    final db = firestoreObrigatorio();
    await gravarNoFirestore(
        () => db.collection('alertas').doc(alerta.id).delete());
  }

  void parar() {
    _assinatura?.cancel();
    _assinatura = null;
    _relogio?.cancel();
  }
}
