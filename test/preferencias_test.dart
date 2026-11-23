import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:enchente_alerta/models/models.dart';
import 'package:enchente_alerta/screens/conta/tela_enderecos.dart';
import 'package:enchente_alerta/screens/conta/tela_notificacoes.dart';
import 'package:enchente_alerta/screens/conta/tela_perfil.dart';
import 'package:enchente_alerta/services/alertas_regiao.dart';
import 'package:enchente_alerta/services/alertas_service.dart';
import 'package:enchente_alerta/services/enderecos_service.dart';
import 'package:enchente_alerta/services/localizacao_service.dart';
import 'package:enchente_alerta/services/notificacoes_service.dart';
import 'package:enchente_alerta/theme/app_theme.dart';

import 'fakes.dart';

class EnderecosFalsos extends EnderecosService {
  final salvos = <Endereco>[];
  final excluidos = <String>[];

  @override
  void iniciar() {}

  @override
  Future<void> salvar(Endereco e) async => salvos.add(e);

  @override
  Future<void> excluir(Endereco e) async => excluidos.add(e.id);
}

class NotificacoesFalsas extends NotificacoesService {
  final lidas = <String>[];
  final excluidas = <String>[];

  @override
  void iniciar() {}

  @override
  Future<void> marcarLida(Notificacao n) async => lidas.add(n.id);

  @override
  Future<void> excluir(Notificacao n) async => excluidas.add(n.id);
}

/// Quadrado de ~1 km em volta de [c].
AreaRisco area(String id, LatLng c) => AreaRisco(
      id: id,
      nome: 'Área $id',
      nivelAtual: Gravidade.grave,
      poligono: [
        LatLng(c.latitude - 0.005, c.longitude - 0.005),
        LatLng(c.latitude - 0.005, c.longitude + 0.005),
        LatLng(c.latitude + 0.005, c.longitude + 0.005),
        LatLng(c.latitude + 0.005, c.longitude - 0.005),
      ],
    );

Alerta alerta(String id, {List<String> areas = const []}) => Alerta(
      id: id,
      titulo: 'Chuva forte $id',
      descricao: '',
      nivel: Gravidade.grave,
      origem: OrigemAlerta.meteorologica,
      areasRiscoIds: areas,
      emitidoEm: DateTime.now(),
      expiraEm: DateTime.now().add(const Duration(hours: 3)),
    );

void main() {
  Future<void> abrir(WidgetTester tester, Widget tela) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.claro, home: tela));
    await tester.pump();
  }

  group('Alertas por região (RF08)', () {
    const casa = LatLng(-10.97, -37.05);
    final perto = area('perto', const LatLng(-10.975, -37.05)); // ~0,5 km
    final longe = area('longe', const LatLng(-10.88, -37.05)); // ~10 km
    final areas = {perto.id: perto, longe.id: longe};

    test('Alerta sem área vale para a cidade toda', () {
      expect(
          alertaValePara(alerta('a'), ponto: casa, raioKm: 1, areas: areas),
          isTrue);
    });

    test('Alerta de área só vale dentro do raio', () {
      final a = alerta('a', areas: ['longe']);
      expect(alertaValePara(a, ponto: casa, raioKm: 2, areas: areas), isFalse);
      expect(alertaValePara(a, ponto: casa, raioKm: 20, areas: areas), isTrue);
      expect(
          alertaValePara(alerta('b', areas: ['perto']),
              ponto: casa, raioKm: 1, areas: areas),
          isTrue);
    });

    test('Sem posição conhecida, mostra o alerta por segurança', () {
      expect(
          alertaValePara(alerta('a', areas: ['longe']),
              ponto: null, raioKm: 1, areas: areas),
          isTrue);
    });

    test('Distância é zero dentro da área', () {
      expect(distanciaAteAreaKm(const LatLng(-10.975, -37.05), perto), 0);
      expect(distanciaAteAreaKm(casa, longe), closeTo(9.4, 0.5));
    });
  });

  testWidgets('Perfil mostra raio, endereço padrão e notificações não lidas',
      (tester) async {
    double? raio;
    await abrir(
      tester,
      PerfilMorador(
        nome: 'Lucas',
        notificacoesAtivas: true,
        raioKm: 2,
        enderecoPadrao: 'Rua A, 120',
        naoLidas: 3,
        aoMeusDados: () {},
        aoNotificacoes: () {},
        aoMudarNotificacoes: (_) {},
        aoMudarRaio: (v) => raio = v,
        aoEnderecoPadrao: () {},
        aoSair: () {},
      ),
    );
    expect(find.text('3 não lidas'), findsOneWidget);
    expect(find.text('Rua A, 120'), findsOneWidget);
    expect(find.text('2 km em volta do seu endereço'), findsOneWidget);

    await tester.tap(find.text('Raio dos alertas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10 km'));
    await tester.pumpAndSettle();
    expect(raio, 10);
  });

  testWidgets('Novo endereço valida e salva', (tester) async {
    final falso = EnderecosFalsos();
    EnderecosService.instance = falso;
    LocalizacaoService.instance = LocalizacaoFalsa();
    await abrir(tester, const TelaFormularioEndereco());

    await tester.tap(find.text('Cadastrar endereço'));
    await tester.pump();
    expect(find.text('Informe a rua.'), findsOneWidget);
    expect(find.text('Escolha o local no mapa (busca ou posição).'),
        findsOneWidget);

    await tester.enterText(find.byKey(const Key('campo-logradouro')), 'Rua A');
    await tester.enterText(find.byKey(const Key('campo-bairro')), 'Farolândia');
    await tester.tap(find.text('Usar minha posição atual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar endereço'));
    await tester.pumpAndSettle();

    expect(falso.salvos, hasLength(1));
    expect(falso.salvos.first.bairro, 'Farolândia');
    expect(falso.salvos.first.cidade, 'Aracaju');
    expect(falso.salvos.first.padrao, isTrue);
  });

  testWidgets('Lista de endereços mostra o padrão e exclui', (tester) async {
    final falso = EnderecosFalsos();
    EnderecosService.instance = falso;
    falso.enderecos.value = const [
      Endereco(
          id: 'e1',
          logradouro: 'Rua A, 120',
          bairro: 'Farolândia',
          cidade: 'Aracaju',
          localizacao: LatLng(-10.97, -37.05),
          padrao: true),
    ];
    await abrir(tester, const TelaEnderecos());
    expect(find.textContaining('Endereço padrão'), findsOneWidget);

    await tester.tap(find.byTooltip('Opções do endereço'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(falso.excluidos, ['e1']);
  });

  testWidgets('Notificações: tocar marca como lida e excluir remove',
      (tester) async {
    final falso = NotificacoesFalsas();
    NotificacoesService.instance = falso;
    AlertasService.instance = AlertasService();
    falso.notificacoes.value = [
      Notificacao(
          id: 'n1',
          mensagem: 'Defesa Civil · Grave: Chuva forte',
          alertaId: 'n1',
          enviadaEm: DateTime.now()),
    ];
    await abrir(tester, const TelaNotificacoes());
    expect(find.text('1 não lida'), findsOneWidget);

    await tester.tap(find.text('Defesa Civil · Grave: Chuva forte'));
    await tester.pumpAndSettle();
    expect(falso.lidas, ['n1']);
    expect(find.textContaining('Este alerta já foi encerrado.'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Excluir notificação'));
    await tester.pumpAndSettle();
    expect(falso.excluidas, ['n1']);
  });
}
