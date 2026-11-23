import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import '../config.dart';

/// Endereço de um fundo de mapa e o nome da pasta onde ele é guardado.
class FonteMapa {
  const FonteMapa(this.nome, this.modelo);

  final String nome;

  /// URL com `{z}`, `{x}` e `{y}`.
  final String modelo;

  String url(int z, int x, int y) => modelo
      .replaceAll('{z}', '$z')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$y');

  static const osm =
      FonteMapa('osm', 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');

  static FonteMapa carto(bool escuro) => FonteMapa(
        escuro ? 'carto_escuro' : 'carto_claro',
        'https://basemaps.cartocdn.com/rastertiles/'
            '${escuro ? 'dark_all' : 'voyager'}/{z}/{x}/{y}.png'
            '?key=${Config.cartoApiKey}',
      );

  /// Fundo usado pelo mapa agora (o mesmo de MapaEnchente).
  static FonteMapa atual(bool escuro) => Config.temChaveCarto ? carto(escuro) : osm;

  /// Fundos que o "Salvar mapa da região" guarda: com a CARTO, o claro e o
  /// escuro, porque o tema segue o aparelho.
  static List<FonteMapa> get paraGuardar =>
      Config.temChaveCarto ? [carto(false), carto(true)] : const [osm];
}

/// Andamento do "Salvar mapa da região".
class ProgressoMapa {
  const ProgressoMapa(this.feitos, this.total, {this.falhas = 0});
  final int feitos;
  final int total;
  final int falhas;
  double get fracao => total == 0 ? 1 : feitos / total;
}

/// Mapa para uso sem internet (RF07, RNF05).
///
/// Cada pedaço (tile) do fundo do mapa que aparece na tela é guardado no
/// aparelho; sem internet, o mapa usa o que está guardado. Com
/// [salvarRegiao], a pessoa guarda de uma vez os arredores de um ponto.
///
/// Feito à mão, em vez do pacote flutter_map_tile_caching: aquele pacote
/// usa licença GPL e um banco nativo (ObjectBox); aqui bastam arquivos.
///
/// O servidor do OpenStreetMap proíbe baixar áreas grandes de uma vez,
/// então a região salva é pequena (cerca de 3 km) e baixada devagar.
class MapaOfflineService {
  MapaOfflineService();

  /// Trocável nos testes.
  static MapaOfflineService instance = MapaOfflineService();

  static const raioPadraoKm = 3.0;
  static const zoomMinimo = 12;
  static const zoomMaximo = 16;

  /// Depois desse tempo o pedaço é baixado de novo (se houver internet).
  static const validade = Duration(days: 14);

  /// `null` quando não está baixando.
  final progresso = ValueNotifier<ProgressoMapa?>(null);

  /// Centro e data da última região salva (lidos de um arquivo).
  final regiaoSalva = ValueNotifier<({LatLng centro, DateTime em})?>(null);

  bool _cancelar = false;
  Future<Directory?>? _pasta;

  Future<Directory?> pasta() => _pasta ??= _abrirPasta();

  Future<Directory?> _abrirPasta() async {
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/mapa_offline');
      await dir.create(recursive: true);
      return dir;
    } catch (e) {
      // Sem a pasta (ex.: testes), o mapa funciona só com a internet.
      debugPrint('Mapa offline indisponível: $e');
      return null;
    }
  }

  File _arquivo(Directory dir, FonteMapa fonte, int z, int x, int y) =>
      File('${dir.path}/${fonte.nome}/$z/$x/$y.png');

  /// Pedaço guardado, ou `null`. Com [soRecente], ignora os vencidos.
  Future<Uint8List?> lerGuardado(FonteMapa fonte, int z, int x, int y,
      {bool soRecente = false}) async {
    final dir = await pasta();
    if (dir == null) return null;
    final arq = _arquivo(dir, fonte, z, x, y);
    try {
      if (!await arq.exists()) return null;
      if (soRecente &&
          DateTime.now().difference(await arq.lastModified()) > validade) {
        return null;
      }
      return await arq.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<void> guardar(
      FonteMapa fonte, int z, int x, int y, Uint8List bytes) async {
    final dir = await pasta();
    if (dir == null) return;
    try {
      final arq = _arquivo(dir, fonte, z, x, y);
      await arq.parent.create(recursive: true);
      await arq.writeAsBytes(bytes, flush: true);
    } catch (e) {
      debugPrint('Não foi possível guardar o mapa: $e');
    }
  }

  /// Baixa um pedaço e guarda. Lança erro se não conseguir.
  Future<Uint8List> baixar(FonteMapa fonte, int z, int x, int y,
      Map<String, String> cabecalhos) async {
    final resposta = await http
        .get(Uri.parse(fonte.url(z, x, y)), headers: cabecalhos)
        .timeout(const Duration(seconds: 15));
    if (resposta.statusCode != 200 || resposta.bodyBytes.isEmpty) {
      throw HttpException('Mapa: código ${resposta.statusCode}');
    }
    await guardar(fonte, z, x, y, resposta.bodyBytes);
    return resposta.bodyBytes;
  }

  /// Pedaços (z, x, y) num raio de [raioKm] em volta de [centro].
  static List<(int, int, int)> pedacosDaRegiao(LatLng centro,
      {double raioKm = raioPadraoKm,
      int zMin = zoomMinimo,
      int zMax = zoomMaximo}) {
    final dLat = raioKm / 111.32;
    final dLon = raioKm / (111.32 * math.cos(centro.latitude * math.pi / 180));
    final lista = <(int, int, int)>[];
    for (var z = zMin; z <= zMax; z++) {
      final (x1, y1) = _pedaco(centro.latitude + dLat, centro.longitude - dLon, z);
      final (x2, y2) = _pedaco(centro.latitude - dLat, centro.longitude + dLon, z);
      for (var x = x1; x <= x2; x++) {
        for (var y = y1; y <= y2; y++) {
          lista.add((z, x, y));
        }
      }
    }
    return lista;
  }

  static (int, int) _pedaco(double lat, double lon, int z) {
    final n = 1 << z;
    final x = ((lon + 180) / 360 * n).floor();
    final r = lat * math.pi / 180;
    final y = ((1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * n)
        .floor();
    return (x.clamp(0, n - 1), y.clamp(0, n - 1));
  }

  /// Guarda os arredores de [centro] para usar sem internet. Devolve
  /// quantos pedaços falharam (0 = tudo certo).
  Future<int> salvarRegiao(LatLng centro,
      {double raioKm = raioPadraoKm}) async {
    if (progresso.value != null) return 0;
    _cancelar = false;
    final pedacos = pedacosDaRegiao(centro, raioKm: raioKm);
    final fontes = FonteMapa.paraGuardar;
    final total = pedacos.length * fontes.length;
    var feitos = 0;
    var falhas = 0;
    progresso.value = ProgressoMapa(0, total);
    const cabecalhos = {
      'User-Agent': 'flutter_map (br.unit.enchentealerta.enchente_alerta)',
    };
    try {
      for (final fonte in fontes) {
        for (final (z, x, y) in pedacos) {
          if (_cancelar) return falhas;
          // Já guardado e recente: não baixa de novo (poupa o servidor).
          if (await lerGuardado(fonte, z, x, y, soRecente: true) == null) {
            try {
              await baixar(fonte, z, x, y, cabecalhos);
              // Devagar, como pede a política de uso do OpenStreetMap.
              await Future<void>.delayed(const Duration(milliseconds: 120));
            } catch (_) {
              falhas++;
            }
          }
          feitos++;
          progresso.value = ProgressoMapa(feitos, total, falhas: falhas);
        }
      }
      if (falhas < total) await _gravarRegiao(centro);
      return falhas;
    } finally {
      progresso.value = null;
    }
  }

  void cancelar() => _cancelar = true;

  Future<void> _gravarRegiao(LatLng centro) async {
    final dir = await pasta();
    if (dir == null) return;
    final agora = DateTime.now();
    try {
      await File('${dir.path}/regiao.txt').writeAsString(
          '${centro.latitude};${centro.longitude};${agora.toIso8601String()}');
      regiaoSalva.value = (centro: centro, em: agora);
    } catch (_) {}
  }

  /// Lê a última região salva (chamar ao abrir a tela).
  Future<void> carregarRegiao() async {
    final dir = await pasta();
    if (dir == null) return;
    try {
      final arq = File('${dir.path}/regiao.txt');
      if (!await arq.exists()) return;
      final p = (await arq.readAsString()).split(';');
      regiaoSalva.value = (
        centro: LatLng(double.parse(p[0]), double.parse(p[1])),
        em: DateTime.parse(p[2]),
      );
    } catch (_) {}
  }

  /// Espaço ocupado pelo mapa guardado, em bytes.
  Future<int> tamanho() async {
    final dir = await pasta();
    if (dir == null) return 0;
    var soma = 0;
    try {
      await for (final f in dir.list(recursive: true)) {
        if (f is File) soma += await f.length();
      }
    } catch (_) {}
    return soma;
  }

  /// Apaga todo o mapa guardado.
  Future<void> limpar() async {
    final dir = await pasta();
    if (dir == null) return;
    try {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
      regiaoSalva.value = null;
    } catch (_) {}
  }
}

/// Fundo do mapa que guarda cada pedaço exibido e, sem internet, usa o que
/// já está guardado.
class TileProviderComCache extends TileProvider {
  TileProviderComCache(this.fonte);

  final FonteMapa fonte;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _PedacoMapa(
        fonte: fonte,
        z: coordinates.z,
        x: coordinates.x,
        y: coordinates.y,
        cabecalhos: Map.of(headers),
      );
}

class _PedacoMapa extends ImageProvider<_PedacoMapa> {
  const _PedacoMapa({
    required this.fonte,
    required this.z,
    required this.x,
    required this.y,
    required this.cabecalhos,
  });

  final FonteMapa fonte;
  final int z, x, y;
  final Map<String, String> cabecalhos;

  @override
  Future<_PedacoMapa> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_PedacoMapa key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(_carregar(decode));

  Future<ImageInfo> _carregar(ImageDecoderCallback decode) async {
    final servico = MapaOfflineService.instance;
    // 1) Guardado e recente: nem usa a internet.
    var bytes = await servico.lerGuardado(fonte, z, x, y, soRecente: true);
    if (bytes == null) {
      try {
        // 2) Baixa e guarda.
        bytes = await servico.baixar(fonte, z, x, y, cabecalhos);
      } catch (e) {
        // 3) Sem internet: usa o guardado, mesmo antigo.
        bytes = await servico.lerGuardado(fonte, z, x, y);
        if (bytes == null) rethrow;
      }
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final codec = await decode(buffer);
    final quadro = await codec.getNextFrame();
    return ImageInfo(image: quadro.image);
  }

  @override
  bool operator ==(Object other) =>
      other is _PedacoMapa &&
      other.fonte.nome == fonte.nome &&
      other.z == z &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(fonte.nome, z, x, y);
}
