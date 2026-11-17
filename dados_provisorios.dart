import 'package:latlong2/latlong.dart';

import '../models/destino.dart';
import '../models/models.dart';

// DADOS PROVISÓRIOS: servem só para as telas funcionarem como no protótipo.
// Depois serão trocados pela localização real do usuário e pelas coleções
// `abrigos` e `rotasFuga` do Firestore.

/// Posição do usuário (Farolândia, Aracaju).
const usuarioProvisorio = LatLng(-10.9640, -37.0510);

final _calculo = Distance();

/// Distância em linha reta, em metros.
double metrosEntre(LatLng a, LatLng b) => _calculo.distance(a, b);

/// Ponto a [metros] do usuário, na direção [rumo] (graus; 0 = norte).
LatLng _aPartirDoUsuario(double metros, double rumo) =>
    _calculo.offset(usuarioProvisorio, metros, rumo);

final locaisSalvos = <Destino>[
  Destino(nome: 'Hosp. Universitário', posicao: _aPartirDoUsuario(3200, 200)),
  Destino(nome: 'Escola Exemplo', posicao: _aPartirDoUsuario(1400, 70)),
  Destino(nome: 'Farolândia', posicao: _aPartirDoUsuario(300, 10)),
];

final sugestoes = <Destino>[
  Destino(
    nome: 'Colégio Arquidiocesano',
    posicao: _aPartirDoUsuario(900, 330),
  ),
];

final abrigos = <Abrigo>[
  Abrigo(
    id: 'ab1',
    nome: 'Esc. Gonçalo Rollemberg Leite',
    bairro: 'Farolândia',
    localizacao: _aPartirDoUsuario(630, 40),
    capacidade: 120,
    vagasDisponiveis: 42,
  ),
  Abrigo(
    id: 'ab2',
    nome: 'Ginásio Fernando Collor',
    bairro: 'Ponto Novo',
    localizacao: _aPartirDoUsuario(1200, 120),
    capacidade: 400,
    vagasDisponiveis: 118,
  ),
  Abrigo(
    id: 'ab3',
    nome: 'Igreja N. Sra. do Perpétuo Socorro',
    bairro: 'Jabotiana',
    localizacao: _aPartirDoUsuario(4500, 280),
    capacidade: 150,
    vagasDisponiveis: 30,
  ),
  Abrigo(
    id: 'ab4',
    nome: 'Centro Comunitário Coroa do Meio',
    bairro: 'Coroa do Meio',
    localizacao: _aPartirDoUsuario(6000, 100),
    capacidade: 200,
    vagasDisponiveis: 12,
  ),
  Abrigo(
    id: 'ab5',
    nome: 'SESI Industrial',
    bairro: 'Industrial',
    localizacao: _aPartirDoUsuario(21000, 330),
    capacidade: 250,
    vagasDisponiveis: 60,
  ),
];

/// Abrigos ativos, do mais perto para o mais longe do usuário.
List<Abrigo> abrigosPorDistancia() {
  final lista = abrigos.where((abrigo) => abrigo.ativo).toList();
  lista.sort(
    (a, b) => a
        .distanciaAte(usuarioProvisorio)
        .compareTo(b.distanciaAte(usuarioProvisorio)),
  );
  return lista;
}

/// Texto da rota provisória (depois virá das áreas evitadas pela rota).
const observacaoProvisoria =
    'Rota vermelha evita a área alagada em Av. Murilo Dantas.';

// Velocidades usadas para estimar o tempo: 4,5 km/h a pé e 14 km/h de carro
// (trânsito lento em dia de chuva).
const _metrosPorMinutoAPe = 75;
const _metrosPorMinutoCarro = 233;

/// Monta uma rota de mentira entre [origem] e [destino]: um traçado em
/// zigue-zague com as distâncias e tempos calculados sobre ele.
RotaFuga rotaProvisoria(LatLng origem, Destino destino) {
  final dLat = destino.posicao.latitude - origem.latitude;
  final dLng = destino.posicao.longitude - origem.longitude;
  // Desvio lateral de 8% da distância, para a linha não sair reta.
  final desvioLat = -dLng * 0.08;
  final desvioLng = dLat * 0.08;

  final pontos = <LatLng>[
    origem,
    LatLng(
      origem.latitude + dLat / 3 + desvioLat,
      origem.longitude + dLng / 3 + desvioLng,
    ),
    LatLng(
      origem.latitude + 2 * dLat / 3 - desvioLat,
      origem.longitude + 2 * dLng / 3 - desvioLng,
    ),
    destino.posicao,
  ];

  var total = 0.0;
  for (var i = 0; i < pontos.length - 1; i++) {
    total += metrosEntre(pontos[i], pontos[i + 1]);
  }
  final metros = total.round();

  return RotaFuga(
    id: 'provisoria',
    // Locais que não são abrigo ficam sem abrigoId.
    abrigoId: destino.abrigoId ?? '',
    pontos: pontos,
    distanciaMetros: metros,
    tempoAPeMin: _minutos(metros, _metrosPorMinutoAPe),
    tempoCarroMin: _minutos(metros, _metrosPorMinutoCarro),
    riscoNaVia: Gravidade.grave,
  );
}

int _minutos(int metros, int metrosPorMinuto) {
  final minutos = (metros / metrosPorMinuto).round();
  return minutos < 1 ? 1 : minutos;
}

/// Alagamentos já encerrados, como no protótipo (tela "06 Histórico").
/// Depois virá da consulta das ocorrências resolvidas ou expiradas.
final historicoProvisorio = <Ocorrencia>[
  _ocorrenciaEncerrada('h1', 'Av. Ivo do Prado, Centro', Gravidade.grave, 80,
      DateTime(2026, 9, 18)),
  _ocorrenciaEncerrada('h2', 'Rua Laranjeiras, Siqueira Campos',
      Gravidade.moderado, 35, DateTime(2026, 7, 11)),
  _ocorrenciaEncerrada('h3', 'Av. Beira Mar, Atalaia', Gravidade.grave, 65,
      DateTime(2026, 4, 10)),
  _ocorrenciaEncerrada('h4', 'Rua José do Prado Franco, Salgado Filho',
      Gravidade.moderado, 28, DateTime(2026, 1, 21)),
  _ocorrenciaEncerrada('h5', 'Av. Tancredo Neves, Ponto Novo', Gravidade.leve,
      12, DateTime(2025, 3, 30)),
  _ocorrenciaEncerrada('h6', 'Rua Dep. Silvério Leite Fontes, Coroa do Meio',
      Gravidade.grave, 90, DateTime(2024, 7, 31)),
];

Ocorrencia _ocorrenciaEncerrada(
  String id,
  String endereco,
  Gravidade gravidade,
  int nivelAguaCm,
  DateTime data,
) =>
    Ocorrencia(
      id: id,
      tipo: TipoOcorrencia.alagamento,
      gravidade: gravidade,
      status: StatusOcorrencia.resolvida,
      endereco: endereco,
      localizacao: usuarioProvisorio,
      nivelAguaCm: nivelAguaCm,
      criadaEm: data,
      expiraEm: data.add(const Duration(hours: 6)),
    );

/// Orientações do Guia de segurança, como no protótipo (tela "08").
/// Depois virão da coleção `guias` do Firestore.
const guiasProvisorios = <GuiaOrientacao>[
  GuiaOrientacao(
      id: 'g1',
      titulo: 'Alertas',
      conteudo: 'Acompanhe os alertas da Defesa Civil',
      fase: FaseGuia.antes,
      ordem: 1),
  GuiaOrientacao(
      id: 'g2',
      titulo: 'Rota de fuga',
      conteudo: 'Conheça a rota de fuga do seu bairro',
      fase: FaseGuia.antes,
      ordem: 2),
  GuiaOrientacao(
      id: 'g3',
      titulo: 'Documentos',
      conteudo: 'Proteja documentos em local alto e seco',
      fase: FaseGuia.antes,
      ordem: 3),
  GuiaOrientacao(
      id: 'g4',
      titulo: 'Áreas alagadas',
      conteudo: 'Evite atravessar áreas alagadas',
      fase: FaseGuia.durante,
      ordem: 1),
  GuiaOrientacao(
      id: 'g5',
      titulo: 'Correntes de água',
      conteudo: 'Não atravesse correntes de água',
      fase: FaseGuia.durante,
      ordem: 2),
  GuiaOrientacao(
      id: 'g6',
      titulo: 'Locais altos',
      conteudo: 'Procure locais altos e seguros',
      fase: FaseGuia.durante,
      ordem: 3),
  GuiaOrientacao(
      id: 'g7',
      titulo: 'Autoridades',
      conteudo: 'Siga as orientações das autoridades',
      fase: FaseGuia.evacuacao,
      ordem: 1),
  GuiaOrientacao(
      id: 'g8',
      titulo: 'Mobilidade reduzida',
      conteudo: 'Ajude pessoas com mobilidade reduzida',
      fase: FaseGuia.evacuacao,
      ordem: 2),
  GuiaOrientacao(
      id: 'g9',
      titulo: 'Essencial',
      conteudo: 'Leve apenas o essencial',
      fase: FaseGuia.evacuacao,
      ordem: 3),
  GuiaOrientacao(
      id: 'g10',
      titulo: 'Defesa Civil',
      conteudo: 'Defesa civil 199',
      fase: FaseGuia.emergencia,
      ordem: 1),
  GuiaOrientacao(
      id: 'g11',
      titulo: 'SAMU',
      conteudo: 'SAMU 192',
      fase: FaseGuia.emergencia,
      ordem: 2),
  GuiaOrientacao(
      id: 'g12',
      titulo: 'Bombeiros',
      conteudo: 'Bombeiros 193',
      fase: FaseGuia.emergencia,
      ordem: 3),
];
