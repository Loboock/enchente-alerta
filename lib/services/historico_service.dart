import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'erro_servico.dart';

/// Histórico de alagamentos e vias obstruídas (coleção `ocorrencias`), em
/// tempo real: os avisos ativos e também os que já acabaram (resolvidos
/// pela Defesa Civil ou expirados).
///
/// Ordena só por `criadaEm`, que tem índice automático no Firestore (sem
/// índice composto). Sem internet, o Firestore entrega o que está salvo no
/// aparelho e [doCache] fica `true`.
class HistoricoService {
  HistoricoService();

  /// Trocável nos testes por uma versão falsa.
  static HistoricoService instance = HistoricoService();

  /// Quantos avisos o histórico mostra, do mais recente ao mais antigo.
  static const limite = 100;

  /// `null` enquanto carrega a primeira vez.
  final ocorrencias = ValueNotifier<List<Ocorrencia>?>(null);

  /// Mensagem de erro da consulta, ou `null`.
  final erro = ValueNotifier<String?>(null);

  /// `true` quando a lista veio do cache do aparelho (sem internet).
  final doCache = ValueNotifier<bool>(false);

  StreamSubscription<Object?>? _assinatura;

  void iniciar() {
    if (_assinatura != null) return;
    final db = firestoreOuNull();
    if (db == null) {
      // Sem Firebase (ex.: testes): lista vazia em vez de "carregando".
      ocorrencias.value ??= const [];
      return;
    }
    _assinatura = db
        .collection('ocorrencias')
        .orderBy('criadaEm', descending: true)
        .limit(limite)
        .snapshots(includeMetadataChanges: true)
        .listen(
      (snap) {
        final lista = <Ocorrencia>[];
        for (final doc in snap.docs) {
          try {
            lista.add(Ocorrencia.fromFirestore(doc));
          } catch (e) {
            // Um documento inválido não pode esconder o histórico inteiro.
            debugPrint('Ocorrência ignorada no histórico: $e');
          }
        }
        ocorrencias.value = lista;
        doCache.value = snap.metadata.isFromCache;
        erro.value = null;
      },
      onError: (Object e) {
        debugPrint('historico: $e');
        erro.value = 'Não foi possível carregar o histórico. '
            'Confira a internet e tente de novo.';
        ocorrencias.value ??= const [];
      },
    );
  }

  /// Refaz a consulta (botão "Tentar de novo").
  void recarregar() {
    parar();
    iniciar();
  }

  void parar() {
    _assinatura?.cancel();
    _assinatura = null;
  }
}

/// Situação do aviso no histórico. Um aviso ATIVA com o prazo vencido conta
/// como expirado: a expiração é feita pelo app (sem Cloud Functions).
StatusOcorrencia situacaoNoHistorico(Ocorrencia o, [DateTime? agora]) {
  if (o.status != StatusOcorrencia.ativa) return o.status;
  return o.estaAtiva(agora) ? StatusOcorrencia.ativa : StatusOcorrencia.expirada;
}
