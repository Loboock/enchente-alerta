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
