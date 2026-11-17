import 'package:latlong2/latlong.dart';

import '../models/models.dart';

export '../utils/geo.dart' show metrosEntre;

// DADOS PROVISÓRIOS: abrigos de exemplo. Depois serão
// trocados pela coleção `abrigos` do Firestore. A posição do usuário e as
// rotas já são reais (LocalizacaoService e RotasService).

/// Posição de teste (Farolândia, Aracaju): usada quando não há GPS.
const usuarioProvisorio = LatLng(-10.9640, -37.0510);

final _calculo = Distance();

/// Ponto a [metros] do usuário, na direção [rumo] (graus; 0 = norte).
LatLng _aPartirDoUsuario(double metros, double rumo) =>
    _calculo.offset(usuarioProvisorio, metros, rumo);

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

/// Abrigos ativos, do mais perto para o mais longe de [de] (por padrão,
/// a posição de teste).
List<Abrigo> abrigosPorDistancia({LatLng de = usuarioProvisorio}) {
  final lista = abrigos.where((abrigo) => abrigo.ativo).toList();
  lista.sort((a, b) => a.distanciaAte(de).compareTo(b.distanciaAte(de)));
  return lista;
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
