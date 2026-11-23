import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../utils/formatacao.dart';
import '../utils/geo.dart';
import 'models.dart';

/// De onde veio o perigo mostrado no mapa.
enum OrigemPerigo { comunidade, defesaCivil }

/// Um ponto ou área alagada que o mapa mostra e que as rotas podem evitar.
///
/// Junta as duas fontes num formato só:
/// - [Ocorrencia] reportada por moradores (um ponto + raio);
/// - [AreaRisco] desenhada pela Defesa Civil (um polígono).
///
/// É um conceito só do app: não vai para o Firestore e por isso não está
/// em `models.dart`.
class Perigo {
  const Perigo._({
    required this.id,
    required this.origem,
    required this.titulo,
    required this.detalhe,
    required this.gravidade,
    required this.poligono,
    required this.centro,
    required this.bloqueia,
    this.raioMetros,
    this.ocorrencia,
    this.area,
  });

  /// Raio do desvio em volta de um aviso da comunidade, por gravidade.
  static const raioPorGravidade = {
    Gravidade.leve: 40.0,
    Gravidade.moderado: 60.0,
    Gravidade.grave: 90.0,
  };

  factory Perigo.daOcorrencia(Ocorrencia o, {DateTime? agora}) {
    final raio = raioPorGravidade[o.gravidade]!;
    return Perigo._(
      id: 'oc:${o.id}',
      origem: OrigemPerigo.comunidade,
      titulo: o.tipo.rotulo,
      detalhe: encurtarEndereco(o.endereco),
      gravidade: o.gravidade,
      centro: o.localizacao,
      raioMetros: raio,
      poligono: circuloComoPoligono(o.localizacao, raio),
      // Só desvia depois de atingir Config.confirmacoesParaBloquear;
      // antes disso o aviso só aparece no mapa, em laranja.
      bloqueia: o.estaAtiva(agora) &&
          o.confirmacoes >= Config.confirmacoesParaBloquear,
      ocorrencia: o,
    );
  }

  /// Áreas da Defesa Civil sempre bloqueiam (fonte oficial).
  factory Perigo.daArea(AreaRisco a) => Perigo._(
        id: 'ar:${a.id}',
        origem: OrigemPerigo.defesaCivil,
        titulo: a.nome,
        detalhe: 'Área de risco da Defesa Civil',
        gravidade: a.nivelAtual,
        centro: centroDe(a.poligono),
        poligono: a.poligono,
        bloqueia: true,
        area: a,
      );

  final String id;
  final OrigemPerigo origem;
  final String titulo;
  final String detalhe;
  final Gravidade gravidade;
  final List<LatLng> poligono;
  final LatLng centro;

  /// Preenchido nos avisos da comunidade (círculo em volta do ponto).
  final double? raioMetros;

  /// true = as rotas desviam deste perigo.
  final bool bloqueia;

  final Ocorrencia? ocorrencia;
  final AreaRisco? area;

  bool get daComunidade => origem == OrigemPerigo.comunidade;

  /// Quantas confirmações ainda faltam para começar a desviar (0 se já
  /// desvia ou se é da Defesa Civil).
  int get faltamConfirmacoes {
    final o = ocorrencia;
    if (o == null || bloqueia) return 0;
    final faltam = Config.confirmacoesParaBloquear - o.confirmacoes;
    return faltam < 0 ? 0 : faltam;
  }

  bool contem(LatLng ponto) {
    final raio = raioMetros;
    if (raio != null) return metrosEntre(ponto, centro) <= raio;
    return pontoNoPoligono(ponto, poligono);
  }

  /// A rota passa por dentro deste perigo? Olha a partir do ponto
  /// [aPartirDe] (na navegação, só o trecho que falta).
  bool cruza(List<LatLng> rota, {int aPartirDe = 0}) {
    final raio = raioMetros;
    for (var i = aPartirDe; i < rota.length; i++) {
      final ponto = rota[i];
      if (raio != null) {
        // Círculo: basta um segmento passar a menos de `raio` do centro.
        if (i + 1 < rota.length &&
            metrosAteSegmento(centro, ponto, rota[i + 1]) <= raio) {
          return true;
        }
        if (metrosEntre(ponto, centro) <= raio) return true;
      } else {
        if (pontoNoPoligono(ponto, poligono)) return true;
        // Ponto do meio do segmento, para trechos longos sem curva.
        if (i + 1 < rota.length) {
          final proximo = rota[i + 1];
          final meio = LatLng(
            (ponto.latitude + proximo.latitude) / 2,
            (ponto.longitude + proximo.longitude) / 2,
          );
          if (pontoNoPoligono(meio, poligono)) return true;
        }
      }
    }
    return false;
  }

  /// Distância aproximada (em metros) entre o perigo e a rota.
  double distanciaAte(List<LatLng> rota) =>
      projetarNaRota(rota, centro).distanciaMetros;
}
