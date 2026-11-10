import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:enchente_alerta/models/models.dart';

/// Testa o mapeamento Dart <-> Firestore: o que é gravado com toFirestore()
/// precisa voltar igual com fromMap() (mesma lógica do fromFirestore).
void main() {
  final data = DateTime(2026, 11, 10, 14, 30);
  const ponto = LatLng(-10.9640, -37.0510);

  group('Enumerações', () {
    test('gravam o código do Firestore e voltam pelo código', () {
      expect(Gravidade.grave.codigo, 'GRAVE');
      expect(PerfilUsuario.defesaCivil.codigo, 'DEFESA_CIVIL');
      expect(enumPorCodigo(TipoOcorrencia.values, 'VIA_OBSTRUIDA'),
          TipoOcorrencia.viaObstruida);
    });

    test('código inválido gera erro', () {
      expect(() => enumPorCodigo(Gravidade.values, 'CRITICO'),
          throwsFormatException);
    });
  });

  group('Ocorrencia', () {
    final ocorrencia = Ocorrencia(
      id: 'oc1',
      tipo: TipoOcorrencia.alagamento,
      gravidade: Gravidade.moderado,
      endereco: 'Av. Murilo Dantas, Farolândia',
      localizacao: ponto,
      nivelAguaCm: 40,
      criadaEm: data,
      expiraEm: data.add(const Duration(hours: 6)),
    );

    test('grava os tipos do Firestore e não grava o autor (RNF07)', () {
      final mapa = ocorrencia.toFirestore();
      expect(mapa['tipo'], 'ALAGAMENTO');
      expect(mapa['status'], 'ATIVA');
      expect(mapa['localizacao'], isA<GeoPoint>());
      expect(mapa['criadaEm'], isA<Timestamp>());
      expect(mapa.containsKey('autorId'), isFalse);
      expect(mapa.containsKey('descricao'), isFalse);
    });

    test('volta igual do Firestore', () {
      final lida = Ocorrencia.fromMap('oc1', ocorrencia.toFirestore());
      expect(lida.tipo, ocorrencia.tipo);
      expect(lida.gravidade, ocorrencia.gravidade);
      expect(lida.localizacao, ocorrencia.localizacao);
      expect(lida.nivelAguaCm, 40);
      expect(lida.expiraEm, ocorrencia.expiraEm);
    });

    test('aceita número decimal do Firestore em campo inteiro', () {
      final mapa = ocorrencia.toFirestore()..['nivelAguaCm'] = 40.0;
      expect(Ocorrencia.fromMap('oc1', mapa).nivelAguaCm, 40);
    });

    test('expira quando expiraEm passa, mesmo com status ATIVA', () {
      expect(ocorrencia.estaAtiva(data.add(const Duration(hours: 1))), isTrue);
      expect(ocorrencia.estaAtiva(data.add(const Duration(hours: 7))), isFalse);
      expect(
        ocorrencia
            .copyWith(status: StatusOcorrencia.resolvida)
            .estaAtiva(data),
        isFalse,
      );
    });
  });

  group('Usuario', () {
    test('conta nova é MORADOR e a preferência fica dentro do documento', () {
      final usuario = Usuario(
        id: 'uid1',
        email: 'ana@exemplo.com',
        nome: 'Ana',
        criadoEm: data,
        preferenciaNotificacao: const PreferenciaNotificacao(raioKm: 5),
      );
      final mapa = usuario.toFirestore();
      expect(mapa['perfil'], 'MORADOR');
      expect(mapa['preferenciaNotificacao'], {'ativa': true, 'raioKm': 5.0});

      final lido = Usuario.fromMap('uid1', mapa);
      expect(lido.ehDefesaCivil, isFalse);
      expect(lido.preferenciaNotificacao!.raioKm, 5);
    });
  });

  group('Abrigo', () {
    final abrigo = Abrigo(
      id: 'ab1',
      nome: 'Escola Exemplo',
      bairro: 'Farolândia',
      localizacao: ponto,
      capacidade: 200,
      vagasDisponiveis: 0,
      atualizadoEm: data,
    );

    test('volta igual do Firestore', () {
      final lido = Abrigo.fromMap('ab1', abrigo.toFirestore());
      expect(lido.nome, 'Escola Exemplo');
      expect(lido.capacidade, 200);
      expect(lido.atualizadoEm, data);
    });

    test('sem vagas não está disponível', () {
      expect(abrigo.estaDisponivel, isFalse);
    });

    test('calcula a distância em metros', () {
      final distancia = abrigo.distanciaAte(const LatLng(-10.9730, -37.0510));
      expect(distancia, closeTo(1000, 20));
    });
  });

  group('RotaFuga e AreaRisco', () {
    test('rota guarda os pontos como GeoPoint e volta igual', () {
      const rota = RotaFuga(
        id: 'r1',
        abrigoId: 'ab1',
        pontos: [ponto, LatLng(-10.9650, -37.0520)],
        distanciaMetros: 800,
        tempoAPeMin: 10,
        tempoCarroMin: 3,
      );
      final mapa = rota.toFirestore();
      expect(mapa['pontos'], everyElement(isA<GeoPoint>()));
      expect(RotaFuga.fromMap('r1', mapa).pontos, rota.pontos);
    });

    test('área de risco sabe se um ponto está dentro dela', () {
      const area = AreaRisco(
        id: 'a1',
        nome: 'Farolândia',
        nivelAtual: Gravidade.grave,
        poligono: [
          LatLng(-10.960, -37.055),
          LatLng(-10.960, -37.047),
          LatLng(-10.968, -37.047),
          LatLng(-10.968, -37.055),
        ],
      );
      expect(area.contem(ponto), isTrue);
      expect(area.contem(const LatLng(-10.900, -37.000)), isFalse);
      expect(AreaRisco.fromMap('a1', area.toFirestore()).poligono.length, 4);
    });
  });

  group('Demais classes', () {
    test('Alerta, Denuncia, Notificacao, Endereco e Guia voltam iguais', () {
      final alerta = Alerta(
        id: 'al1',
        titulo: 'Chuva forte',
        descricao: 'Risco de alagamento',
        nivel: Gravidade.grave,
        origem: OrigemAlerta.meteorologica,
        areasRiscoIds: const ['a1'],
        emitidoEm: data,
        expiraEm: data.add(const Duration(hours: 3)),
      );
      expect(Alerta.fromMap('al1', alerta.toFirestore()).areasRiscoIds, ['a1']);

      final denuncia = Denuncia(
        id: 'd1',
        autorId: 'uid1',
        motivo: MotivoDenuncia.aguaBaixou,
        criadaEm: data,
      );
      expect(Denuncia.fromMap('d1', denuncia.toFirestore()).motivo,
          MotivoDenuncia.aguaBaixou);

      final notificacao =
          Notificacao(id: 'n1', mensagem: 'Alerta grave', enviadaEm: data);
      expect(Notificacao.fromMap('n1', notificacao.toFirestore()).lida, isFalse);

      const endereco = Endereco(
        id: 'e1',
        logradouro: 'Rua A',
        bairro: 'Farolândia',
        cidade: 'Aracaju',
        localizacao: ponto,
        padrao: true,
      );
      expect(Endereco.fromMap('e1', endereco.toFirestore()).padrao, isTrue);

      const guias = [
        GuiaOrientacao(
            id: 'g2', titulo: 'B', conteudo: '...', fase: FaseGuia.antes, ordem: 2),
        GuiaOrientacao(
            id: 'g1', titulo: 'A', conteudo: '...', fase: FaseGuia.antes, ordem: 1),
        GuiaOrientacao(
            id: 'g3', titulo: 'C', conteudo: '...', fase: FaseGuia.depois),
      ];
      expect(
        GuiaOrientacao.filtrarPorFase(guias, FaseGuia.antes).map((g) => g.id),
        ['g1', 'g2'],
      );
      expect(GuiaOrientacao.fromMap('g1', guias[1].toFirestore()).fase,
          FaseGuia.antes);
    });
  });
}
