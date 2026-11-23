import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Avisa quando o aparelho fica sem internet (RNF05), para as telas
/// mostrarem a faixa "Sem internet" e explicarem o que continua
/// funcionando (mapa guardado, avisos e histórico salvos no aparelho).
///
/// Wi-Fi ou dados ligados não garantem internet de verdade, mas é o sinal
/// que o sistema dá sem gastar dados; as telas também tratam o erro de
/// cada consulta.
class ConexaoService {
  ConexaoService();

  /// Trocável nos testes.
  static ConexaoService instance = ConexaoService();

  /// `true` enquanto há Wi-Fi ou dados móveis.
  final online = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _assinatura;

  void iniciar() {
    if (_assinatura != null) return;
    try {
      final c = Connectivity();
      _assinatura = c.onConnectivityChanged.listen(_atualizar,
          onError: (Object e) => debugPrint('conexao: $e'));
      c.checkConnectivity().then(_atualizar).catchError((Object e) {
        debugPrint('conexao: $e');
      });
    } catch (e) {
      // Sem o plugin (ex.: testes): considera conectado.
      debugPrint('conexao: $e');
    }
  }

  void _atualizar(List<ConnectivityResult> r) {
    online.value = r.any((c) => c != ConnectivityResult.none);
  }

  void parar() {
    _assinatura?.cancel();
    _assinatura = null;
  }
}
