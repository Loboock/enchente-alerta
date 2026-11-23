import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:enchente_alerta/models/models.dart';
import 'package:enchente_alerta/screens/defesa_civil/tela_areas_risco.dart';
import 'package:enchente_alerta/screens/defesa_civil/tela_guia_defesa_civil.dart';
import 'package:enchente_alerta/screens/defesa_civil/tela_rotas_fuga_defesa_civil.dart';
import 'package:enchente_alerta/screens/guia/tela_guia.dart';
import 'package:enchente_alerta/services/abrigos_service.dart';
import 'package:enchente_alerta/services/areas_risco_service.dart';
import 'package:enchente_alerta/services/guias_service.dart';
import 'package:enchente_alerta/services/localizacao_service.dart';
import 'package:enchente_alerta/services/perigos_service.dart';
import 'package:enchente_alerta/services/rotas_fuga_service.dart';
import 'package:enchente_alerta/theme/app_theme.dart';

import 'fakes.dart';

class AreasFalsas extends AreasRiscoService {
  final salvas = <AreaRisco>[];
  @override
  Future<void> salvar(AreaRisco area) async => salvas.add(area);
}

class RotasFalsasDC extends RotasFugaService {
  final salvas = <RotaFuga>[];
  @override
  void iniciar() {}
  @override
  Future<void> salvar(RotaFuga rota) async => salvas.add(rota);
}

class GuiasFalsos extends GuiasService {
  final salvos = <GuiaOrientacao>[];
  @override
  void iniciar() {}
  @override
  Future<void> salvar(GuiaOrientacao g) async => salvos.add(g);
}

class AbrigosFixos extends AbrigosService {
  @override
  void iniciar() {}
}

void main() {
  setUp(() {
    LocalizacaoService.instance = LocalizacaoFalsa();
    PerigosService.instance = PerigosService();
  });

  Future<void> abrir(WidgetTester tester, Widget tela) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.claro, home: tela));
    await tester.pump();
  }

  /// Toca em 3 lugares diferentes do mapa do editor.
  Future<void> marcarPontos(WidgetTester tester, int quantos) async {
    final mapa = tester.getRect(find.byType(FlutterMap));
    for (var i = 0; i < quantos; i++) {
      await tester.tapAt(mapa.center + Offset(-60.0 + 60 * i, (i.isOdd ? 50 : -50)));
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  test('Distância e tempos da rota são calculados pelos pontos', () {
    final r = RotasFugaService.montar(
      id: '',
      abrigoId: 'a1',
      pontos: const [LatLng(-10.97, -37.05), LatLng(-10.96, -37.05)],
      riscoNaVia: Gravidade.leve,
      interditada: false,
    );
    expect(r.distanciaMetros, closeTo(1106, 10));
    expect(r.tempoAPeMin, 15);
    expect(r.tempoCarroMin, 3);
  });

  testWidgets('Nova área de risco exige nome e 3 pontos no mapa',
      (tester) async {
    final falsas = AreasFalsas();
    AreasRiscoService.instance = falsas;
    await abrir(tester, const TelaFormularioArea());

    await tester.tap(find.text('Cadastrar área'));
    await tester.pump();
    expect(find.text('Informe o nome da área.'), findsOneWidget);
    expect(find.text('Marque pelo menos 3 pontos no mapa.'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('campo-nome-area')), 'Margem do Rio Poxim');
    await marcarPontos(tester, 3);
    expect(find.text('3 ponto(s) marcado(s).'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await tester.pump();
    expect(find.text('2 ponto(s) marcado(s).'), findsOneWidget);
    await marcarPontos(tester, 1);

    await tester.tap(find.text('Grave'));
    await tester.tap(find.text('Cadastrar área'));
    await tester.pumpAndSettle();
    expect(falsas.salvas, hasLength(1));
    expect(falsas.salvas.first.nome, 'Margem do Rio Poxim');
    expect(falsas.salvas.first.nivelAtual, Gravidade.grave);
    expect(falsas.salvas.first.poligono, hasLength(3));
  });

  testWidgets('Nova rota de fuga termina no abrigo escolhido', (tester) async {
    final rotas = RotasFalsasDC();
    RotasFugaService.instance = rotas;
    final abrigos = AbrigosFixos();
    AbrigosService.instance = abrigos;
    abrigos.cadastrados.value = const [
      Abrigo(
        id: 'a1',
        nome: 'Escola Teste',
        bairro: 'Centro',
        capacidade: 100,
        vagasDisponiveis: 50,
        localizacao: LatLng(-10.95, -37.07),
      ),
    ];
    await abrir(tester, const TelaFormularioRota());

    await tester.tap(find.text('Cadastrar rota'));
    await tester.pump();
    expect(find.text('Escolha o abrigo de destino.'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escola Teste').last);
    await tester.pumpAndSettle();
    await marcarPontos(tester, 2);
    await tester.tap(find.text('Cadastrar rota'));
    await tester.pumpAndSettle();

    expect(rotas.salvas, hasLength(1));
    final r = rotas.salvas.first;
    expect(r.abrigoId, 'a1');
    expect(r.pontos.last, const LatLng(-10.95, -37.07));
    expect(r.pontos, hasLength(3));
    expect(r.distanciaMetros, greaterThan(0));
  });

  testWidgets('Guia mostra o publicado pela Defesa Civil', (tester) async {
    final guias = GuiasFalsos();
    GuiasService.instance = guias;
    await abrir(tester, const TelaGuia());
    // Sem nada publicado: guia de exemplo.
    expect(find.text('Acompanhe os alertas da Defesa Civil'), findsOneWidget);

    guias.publicadas.value = const [
      GuiaOrientacao(
          id: 'g1',
          titulo: 'Energia',
          conteudo: 'Desligue a energia antes de sair',
          fase: FaseGuia.antes),
    ];
    await tester.pump();
    expect(find.text('Desligue a energia antes de sair'), findsOneWidget);
    expect(find.text('Acompanhe os alertas da Defesa Civil'), findsNothing);
  });

  testWidgets('Nova orientação do guia valida e publica', (tester) async {
    final guias = GuiasFalsos();
    GuiasService.instance = guias;
    await abrir(tester, const TelaFormularioGuia());

    await tester.tap(find.text('Publicar orientação'));
    await tester.pump();
    expect(find.text('Escreva a orientação (pelo menos 5 letras).'),
        findsOneWidget);

    await tester.enterText(find.byKey(const Key('campo-conteudo-guia')),
        'Desligue a energia antes de sair');
    await tester.enterText(find.byKey(const Key('campo-titulo-guia')), 'Energia');
    await tester.tap(find.text('Publicar orientação'));
    await tester.pumpAndSettle();
    expect(guias.salvos.single.fase, FaseGuia.antes);
    expect(guias.salvos.single.titulo, 'Energia');
  });

  testWidgets('Lista de áreas mostra o botão de cadastro', (tester) async {
    await abrir(tester, const TelaAreasRisco());
    expect(find.text('Nova área de risco'), findsOneWidget);
    expect(find.text('Nenhuma área de risco cadastrada.'), findsOneWidget);
  });
}
