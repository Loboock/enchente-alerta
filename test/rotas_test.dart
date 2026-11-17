import 'dart:convert';

import 'package:enchente_alerta/models/models.dart';
import 'package:enchente_alerta/models/perigo.dart';
import 'package:enchente_alerta/models/rota_calculada.dart';
import 'package:enchente_alerta/services/rotas_service.dart';
import 'package:enchente_alerta/utils/geo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const origem = LatLng(-10.9640, -37.0510);
  const destino = LatLng(-10.9580, -37.0450);
  final agora = DateTime(2026, 11, 16, 20);

  Ocorrencia ocorrencia({
    required LatLng em,
    int confirmacoes = 1,
    String id = 'oc1',
  }) =>
      Ocorrencia(
        id: id,
        tipo: TipoOcorrencia.alagamento,
        gravidade: Gravidade.moderado,
        endereco: 'Av. Murilo Dantas',
        localizacao: em,
        nivelAguaCm: 40,
        criadaEm: agora,
        expiraEm: agora.add(const Duration(hours: 4)),
        confirmacoes: confirmacoes,
      );

  group('Perigo', () {
    test('aviso da comunidade só bloqueia com 2 confirmações', () {
      final meio = LatLng(
        (origem.latitude + destino.latitude) / 2,
        (origem.longitude + destino.longitude) / 2,
      );
      final sozinho = Perigo.daOcorrencia(ocorrencia(em: meio), agora: agora);
      final confirmado = Perigo.daOcorrencia(
        ocorrencia(em: meio, confirmacoes: 2),
        agora: agora,
      );

      expect(sozinho.bloqueia, isFalse);
      expect(sozinho.faltamConfirmacoes, 1);
      expect(confirmado.bloqueia, isTrue);
      expect(confirmado.faltamConfirmacoes, 0);
    });

    test('aviso expirado não bloqueia', () {
      final p = Perigo.daOcorrencia(
        ocorrencia(em: origem, confirmacoes: 5),
        agora: agora.add(const Duration(hours: 5)),
      );
      expect(p.bloqueia, isFalse);
    });

    test('área da Defesa Civil sempre bloqueia', () {
      const area = AreaRisco(
        id: 'a1',
        nome: 'Bairro baixo',
        nivelAtual: Gravidade.leve,
        poligono: [
          LatLng(-10.96, -37.05),
          LatLng(-10.96, -37.04),
          LatLng(-10.97, -37.04),
          LatLng(-10.97, -37.05),
        ],
      );
      final p = Perigo.daArea(area);
      expect(p.bloqueia, isTrue);
      expect(p.contem(const LatLng(-10.965, -37.045)), isTrue);
      expect(p.contem(const LatLng(-10.95, -37.045)), isFalse);
    });

    test('sabe se a rota passa por dentro', () {
      final meio = LatLng(
        (origem.latitude + destino.latitude) / 2,
        (origem.longitude + destino.longitude) / 2,
      );
      final noCaminho = Perigo.daOcorrencia(ocorrencia(em: meio), agora: agora);
      final longe = Perigo.daOcorrencia(
        ocorrencia(em: const LatLng(-10.90, -37.00)),
        agora: agora,
      );
      // Rota com só 2 pontos: o círculo cruza o segmento, sem vértice dentro.
      expect(noCaminho.cruza([origem, destino]), isTrue);
      expect(longe.cruza([origem, destino]), isFalse);
    });
  });

  group('Geometria', () {
    test('projeta o ponto sobre a rota e mede o percorrido', () {
      final rota = RotaCalculada(
        modo: ModoTransporte.aPe,
        pontos: const [
          LatLng(0, 0),
          LatLng(0, 0.001),
          LatLng(0, 0.002),
        ],
        distanciaMetros: 222,
        duracaoSeg: 160,
        passos: const [],
      );
      // Um pouco ao norte do meio do segundo segmento.
      final p = projetarNaRota(rota.pontos, const LatLng(0.0001, 0.0015));
      expect(p.segmento, 1);
      expect(p.fracao, closeTo(0.5, 0.01));
      expect(p.distanciaMetros, closeTo(11, 1));
      expect(rota.percorrido(p), closeTo(167, 2));
    });

    test('círculo vira polígono com o raio certo', () {
      final poligono = circuloComoPoligono(origem, 60);
      expect(poligono, hasLength(12));
      for (final v in poligono) {
        expect(metrosEntre(origem, v), closeTo(60, 1.5));
      }
    });
  });

  group('RotasService (OpenRouteService)', () {
    final respostaOrs = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              [-37.0510, -10.9640],
              [-37.0480, -10.9640],
              [-37.0450, -10.9580],
            ],
          },
          'properties': {
            'summary': {'distance': 1234.5, 'duration': 300.0},
            'segments': [
              {
                'steps': [
                  {
                    'distance': 330.0,
                    'duration': 80.0,
                    'type': 11,
                    'instruction': 'Siga para leste na Rua A',
                    'name': 'Rua A',
                    'way_points': [0, 1],
                  },
                  {
                    'distance': 900.0,
                    'duration': 220.0,
                    'type': 0,
                    'instruction': 'Vire à esquerda na Av. B',
                    'name': 'Av. B',
                    'way_points': [1, 2],
                  },
                  {
                    'distance': 0.0,
                    'duration': 0.0,
                    'type': 10,
                    'instruction': 'Chegou ao destino',
                    'name': '-',
                    'way_points': [2, 2],
                  },
                ],
              },
            ],
          },
        },
      ],
    };

    test('manda só os perigos que bloqueiam e lê a resposta', () async {
      late Map<String, dynamic> corpoEnviado;
      late http.Request pedido;
      final cliente = MockClient((req) async {
        pedido = req;
        corpoEnviado = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(respostaOrs),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final servico = RotasService(cliente: cliente, chave: 'chave-teste');

      const perto = LatLng(-10.9640, -37.0490);
      final confirmado = Perigo.daOcorrencia(
        ocorrencia(em: perto, confirmacoes: 3, id: 'ok'),
        agora: agora,
      );
      final naoConfirmado = Perigo.daOcorrencia(
        ocorrencia(em: perto, id: 'novo'),
        agora: agora,
      );
      // Na origem: não dá para evitar, só avisa.
      final naOrigem = Perigo.daOcorrencia(
        ocorrencia(em: origem, confirmacoes: 2, id: 'origem'),
        agora: agora,
      );

      final rota = await servico.calcular(
        origem: origem,
        destino: destino,
        modo: ModoTransporte.carro,
        perigos: [confirmado, naoConfirmado, naOrigem],
      );

      expect(pedido.url.host, 'api.heigit.org');
      expect(
        pedido.url.path,
        '/openrouteservice/v2/directions/driving-car/geojson',
      );
      expect(pedido.headers['Authorization'], 'chave-teste');
      expect(corpoEnviado['coordinates'], [
        [origem.longitude, origem.latitude],
        [destino.longitude, destino.latitude],
      ]);
      final evitar = corpoEnviado['options']['avoid_polygons'] as Map;
      expect(evitar['type'], 'MultiPolygon');
      final poligonos = evitar['coordinates'] as List;
      expect(poligonos, hasLength(1)); // só o confirmado
      final anel = (poligonos.first as List).first as List;
      expect(anel.first, anel.last); // anel fechado (GeoJSON)

      expect(rota.pontos, hasLength(3));
      expect(rota.pontos.first, origem);
      expect(rota.distanciaMetros, 1234.5);
      expect(rota.duracaoMin, 5);
      expect(rota.passos, hasLength(3));
      expect(rota.passos[1].instrucao, 'Vire à esquerda na Av. B');
      expect(rota.passos[2].via, ''); // "-" vira vazio
      expect(rota.perigosEvitados.map((p) => p.id), ['oc:ok']);
      expect(rota.perigosInevitaveis.map((p) => p.id), ['oc:origem']);
      expect(rota.avisosNoCaminho.map((p) => p.id), ['oc:novo']);
    });

    test('sem caminho possível vira mensagem clara', () async {
      final cliente = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': 2009, 'message': 'Route could not be found'},
          }),
          404,
        ),
      );
      final servico = RotasService(cliente: cliente, chave: 'x');
      expect(
        () => servico.calcular(
          origem: origem,
          destino: destino,
          modo: ModoTransporte.aPe,
        ),
        throwsA(
          isA<RotaException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('Não há caminho seguro'),
          ),
        ),
      );
    });

    test('sem chave avisa em vez de chamar a internet', () {
      final servico = RotasService(
        cliente: MockClient((_) async => fail('não devia chamar')),
        chave: '',
      );
      expect(servico.buscaDisponivel, isFalse);
      expect(
        () => servico.calcular(
          origem: origem,
          destino: destino,
          modo: ModoTransporte.carro,
        ),
        throwsA(isA<RotaException>()),
      );
    });
  });
}
