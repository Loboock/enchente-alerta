import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../data/dados_provisorios.dart';

/// Posição do usuário num instante.
class PosicaoUsuario {
  const PosicaoUsuario({
    required this.ponto,
    this.rumo,
    this.velocidade = 0,
    this.precisaoMetros,
    this.deTeste = false,
  });

  /// Posição fixa usada quando não há GPS (emulador, permissão negada).
  const PosicaoUsuario.teste()
      : ponto = usuarioProvisorio,
        rumo = null,
        velocidade = 0,
        precisaoMetros = null,
        deTeste = true;

  final LatLng ponto;

  /// Direção do movimento em graus (0 = norte). Null quando parado.
  final double? rumo;

  /// Metros por segundo.
  final double velocidade;
  final double? precisaoMetros;

  /// true = não é o GPS de verdade.
  final bool deTeste;
}

/// GPS do aparelho. Um único acompanhamento para o app inteiro: as telas
/// leem [posicao] (mapa do início, rota e navegação).
class LocalizacaoService {
  LocalizacaoService();

  /// Trocável nos testes por uma versão falsa.
  static LocalizacaoService instance = LocalizacaoService();

  /// Última posição conhecida (null enquanto o GPS não respondeu).
  final posicao = ValueNotifier<PosicaoUsuario?>(null);

  /// Mensagem para mostrar quando o GPS não está disponível.
  String? problema;

  bool _iniciado = false;
  StreamSubscription<Position>? _assinatura;

  /// Pede permissão (só na primeira vez) e começa a acompanhar o GPS.
  Future<void> iniciar() async {
    if (_iniciado) return;
    _iniciado = true;
    // Nunca avisa os ouvintes no meio da construção de uma tela.
    await Future<void>.value();

    if (Config.usarLocalizacaoDeTeste) {
      posicao.value = const PosicaoUsuario.teste();
      return;
    }
    if (!await _temPermissao()) {
      posicao.value = const PosicaoUsuario.teste();
      return;
    }

    try {
      final ultima = await Geolocator.getLastKnownPosition();
      if (ultima != null && posicao.value == null) {
        posicao.value = _converter(ultima);
      }
    } catch (_) {
      // Nem todo aparelho tem a última posição guardada.
    }

    try {
      _assinatura = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3,
        ),
      ).listen(
        (p) {
          problema = null;
          posicao.value = _converter(p);
        },
        onError: (Object _) {
          problema = 'Não foi possível ler o GPS.';
          posicao.value ??= const PosicaoUsuario.teste();
        },
      );
    } catch (_) {
      problema = 'Não foi possível ler o GPS.';
      posicao.value ??= const PosicaoUsuario.teste();
    }
  }

  /// Posição atual, esperando o GPS até 10 s. Se não vier, usa a de teste.
  Future<PosicaoUsuario> atual() async {
    await iniciar();
    final agora = posicao.value;
    if (agora != null) return agora;

    final completer = Completer<PosicaoUsuario>();
    void ouvir() {
      final valor = posicao.value;
      if (valor != null && !completer.isCompleted) completer.complete(valor);
    }

    posicao.addListener(ouvir);
    try {
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          problema = 'O GPS demorou para responder.';
          return const PosicaoUsuario.teste();
        },
      );
    } finally {
      posicao.removeListener(ouvir);
    }
  }

  Future<bool> _temPermissao() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        problema = 'Ative a localização do celular.';
        return false;
      }
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        problema = 'Permita o acesso à localização nas configurações.';
        return false;
      }
      return true;
    } catch (_) {
      // Sem o plugin (ex.: flutter test).
      problema = 'Localização indisponível.';
      return false;
    }
  }

  PosicaoUsuario _converter(Position p) => PosicaoUsuario(
        ponto: LatLng(p.latitude, p.longitude),
        // Parado, o "heading" do GPS é lixo: só usa em movimento.
        rumo: p.speed > 1 && p.heading >= 0 ? p.heading : null,
        velocidade: p.speed < 0 ? 0 : p.speed,
        precisaoMetros: p.accuracy,
      );

  Future<void> parar() async {
    await _assinatura?.cancel();
    _assinatura = null;
    _iniciado = false;
  }
}
