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
