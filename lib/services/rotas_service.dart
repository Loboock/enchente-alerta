import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../models/destino.dart';
import '../models/perigo.dart';
import '../models/rota_calculada.dart';

/// Erro já traduzido para mostrar na tela.
class RotaException implements Exception {
  RotaException(this.mensagem);
  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Rotas e busca de endereços com o OpenRouteService (openrouteservice.org).
///
/// O ponto principal é [calcular]: manda as áreas alagadas em
/// `options.avoid_polygons`, e o próprio serviço acha um caminho que não
/// passa por elas.
class RotasService {
  RotasService({http.Client? cliente, String? chave})
      : _cliente = cliente ?? http.Client(),
        _chave = chave ?? Config.orsApiKey;

  /// Trocável nos testes por uma versão falsa.
  static RotasService instance = RotasService();

  // Endereços novos da HeiGIT (o antigo api.openrouteservice.org foi
  // desativado em 2026). Rotas no openrouteservice, endereços no Pelias.
  static const _baseRotas = 'https://api.heigit.org/openrouteservice';
  static const _baseEnderecos = 'https://api.heigit.org/pelias/v1';
  static const _tempoLimite = Duration(seconds: 20);

  /// Perigos a menos desta distância da rota contam como "evitados".
  static const _distanciaEvitado = 500.0;

  final http.Client _cliente;
  final String _chave;

  /// A busca de endereços só funciona com a chave configurada.
  bool get buscaDisponivel => _chave.isNotEmpty;

  Future<RotaCalculada> calcular({
    required LatLng origem,
    required LatLng destino,
    required ModoTransporte modo,
    List<Perigo> perigos = const [],
  }) async {
    if (_chave.isEmpty) {
      throw RotaException(
        'Falta a chave do OpenRouteService. Veja docs/rotas-e-mapa.md.',
      );
    }

    // Não dá para evitar a área onde a pessoa já está ou para onde vai:
    // o serviço recusaria a rota inteira. Esses viram só um alerta.
    final bloqueios = perigos.where((p) => p.bloqueia).toList();
    final inevitaveis = bloqueios
        .where((p) => p.contem(origem) || p.contem(destino))
        .toList();
    final evitar = bloqueios.where((p) => !inevitaveis.contains(p)).toList();

    final corpo = <String, dynamic>{
      'coordinates': [_lngLat(origem), _lngLat(destino)],
      'language': 'pt',
      'instructions': true,
      'units': 'm',
      if (evitar.isNotEmpty)
        'options': {
          'avoid_polygons': {
            'type': 'MultiPolygon',
            'coordinates': [
              for (final p in evitar) [_anelFechado(p.poligono)],
            ],
          },
        },
    };

    final resposta = await _enviar(
      () => _cliente.post(
        Uri.parse('$_baseRotas/v2/directions/${modo.perfilOrs}/geojson'),
        headers: {
          'Authorization': _chave,
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/geo+json, application/json',
        },
        body: jsonEncode(corpo),
      ),
    );

    final rota = _lerRota(resposta, modo);
    final naoBloqueiam = perigos.where((p) => !p.bloqueia);
    return RotaCalculada(
      modo: modo,
      pontos: rota.pontos,
      distanciaMetros: rota.distanciaMetros,
      duracaoSeg: rota.duracaoSeg,
      passos: rota.passos,
      perigosEvitados: [
        for (final p in evitar)
          if (p.distanciaAte(rota.pontos) <= _distanciaEvitado) p,
      ],
      avisosNoCaminho: [
        for (final p in naoBloqueiam)
          if (p.cruza(rota.pontos)) p,
      ],
      perigosInevitaveis: inevitaveis,
    );
  }

  /// Sugestões de endereço enquanto a pessoa digita (só no Brasil,
  /// priorizando o que está perto de [perto]).
  Future<List<Destino>> buscarEnderecos(String texto, {LatLng? perto}) async {
    if (!buscaDisponivel || texto.trim().length < 3) return const [];
    final uri = Uri.parse('$_baseEnderecos/autocomplete').replace(
      queryParameters: {
        'api_key': _chave,
        'text': texto.trim(),
        'boundary.country': 'BR',
        'size': '6',
        'lang': 'pt',
        if (perto != null) 'focus.point.lat': '${perto.latitude}',
        if (perto != null) 'focus.point.lon': '${perto.longitude}',
      },
    );
    final json = await _enviar(() => _cliente.get(uri));
    return [
      for (final f in (json['features'] as List? ?? const []))
        ?_lerDestino(f as Map<String, dynamic>),
    ];
  }

  /// Endereço (texto) de um ponto, para o aviso reportado pelo usuário.
  Future<String?> enderecoDe(LatLng ponto) async {
    if (!buscaDisponivel) return null;
    try {
      final uri = Uri.parse('$_baseEnderecos/reverse').replace(
        queryParameters: {
          'api_key': _chave,
          'point.lat': '${ponto.latitude}',
          'point.lon': '${ponto.longitude}',
          'size': '1',
          'lang': 'pt',
        },
      );
      final json = await _enviar(() => _cliente.get(uri));
      final features = json['features'] as List? ?? const [];
      if (features.isEmpty) return null;
      final props = (features.first as Map)['properties'] as Map? ?? const {};
      return (props['label'] ?? props['name']) as String?;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>> _enviar(
    Future<http.Response> Function() requisicao,
  ) async {
    final http.Response resposta;
    try {
      resposta = await requisicao().timeout(_tempoLimite);
    } on TimeoutException {
      throw RotaException('O serviço de rotas demorou demais. Tente de novo.');
    } catch (_) {
      throw RotaException('Sem conexão com a internet.');
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      json = const {};
    }

    if (resposta.statusCode == 200) return json;

    final erro = json['error'];
    final codigo = erro is Map ? erro['code'] : null;
    switch (resposta.statusCode) {
      case 401:
      case 403:
        throw RotaException('Chave do OpenRouteService inválida.');
      case 429:
        throw RotaException(
          'Limite diário de rotas atingido. Tente mais tarde.',
        );
    }
    // 2009/2010/2099: não há caminho (ex.: todas as saídas alagadas).
    if (codigo == 2009 || codigo == 2010 || codigo == 2099) {
      throw RotaException(
        'Não há caminho seguro até esse destino evitando as áreas alagadas. '
        'Escolha outro abrigo ou siga as orientações da Defesa Civil.',
      );
    }
    if (codigo == 2004) {
      throw RotaException('Destino longe demais para calcular a rota.');
    }
    throw RotaException('Não foi possível calcular a rota agora.');
  }

  ({
    List<LatLng> pontos,
    double distanciaMetros,
    double duracaoSeg,
    List<PassoRota> passos,
  }) _lerRota(Map<String, dynamic> json, ModoTransporte modo) {
    final features = json['features'] as List? ?? const [];
    if (features.isEmpty) {
      throw RotaException('Não foi possível calcular a rota agora.');
    }
    final feature = features.first as Map<String, dynamic>;
    final geometria = feature['geometry'] as Map<String, dynamic>;
    final pontos = [
      for (final c in geometria['coordinates'] as List)
        LatLng(_num((c as List)[1]), _num(c[0])),
    ];

    final props = feature['properties'] as Map<String, dynamic>? ?? const {};
    final resumo = props['summary'] as Map<String, dynamic>? ?? const {};
    final passos = <PassoRota>[];
    for (final segmento in props['segments'] as List? ?? const []) {
      for (final s in (segmento as Map)['steps'] as List? ?? const []) {
        final passo = s as Map<String, dynamic>;
        final indices = passo['way_points'] as List? ?? const [0, 0];
        passos.add(
          PassoRota(
            tipo: (passo['type'] as num?)?.toInt() ?? 6,
            instrucao: passo['instruction'] as String? ?? '',
            via: _via(passo['name']),
            distanciaMetros: _num(passo['distance']),
            duracaoSeg: _num(passo['duration']),
            inicio: (indices[0] as num).toInt(),
            fim: (indices[1] as num).toInt(),
          ),
        );
      }
    }

    return (
      pontos: pontos,
      distanciaMetros: _num(resumo['distance']),
      duracaoSeg: _num(resumo['duration']),
      passos: passos,
    );
  }

  Destino? _lerDestino(Map<String, dynamic> feature) {
    final geometria = feature['geometry'] as Map?;
    final coords = geometria?['coordinates'] as List?;
    final props = feature['properties'] as Map? ?? const {};
    if (coords == null || coords.length < 2) return null;
    final nome = (props['name'] ?? props['label']) as String?;
    if (nome == null) return null;
    return Destino(
      nome: nome,
      posicao: LatLng(_num(coords[1]), _num(coords[0])),
      detalhe: props['label'] as String?,
    );
  }

  static String _via(Object? nome) {
    final texto = nome as String? ?? '';
    // O ORS usa "-" quando a via não tem nome.
    return texto == '-' ? '' : texto;
  }

  static double _num(Object? valor) => (valor as num?)?.toDouble() ?? 0;

  static List<double> _lngLat(LatLng p) => [p.longitude, p.latitude];

  /// GeoJSON exige o primeiro ponto repetido no fim do anel.
  static List<List<double>> _anelFechado(List<LatLng> pontos) => [
        for (final p in pontos) _lngLat(p),
        _lngLat(pontos.first),
      ];
}
