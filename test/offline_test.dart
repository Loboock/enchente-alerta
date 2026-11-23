import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:enchente_alerta/screens/offline/tela_mapa_offline.dart';
import 'package:enchente_alerta/services/conexao_service.dart';
import 'package:enchente_alerta/services/mapa_offline_service.dart';
import 'package:enchente_alerta/theme/app_theme.dart';
import 'package:enchente_alerta/widgets/faixa_sem_internet.dart';

/// Não usa disco nem internet: só registra o que a tela pediu.
class MapaOfflineFalso extends MapaOfflineService {
  final salvos = <LatLng>[];
  var bytes = 0;

  @override
  Future<int> salvarRegiao(LatLng centro, {double raioKm = 3}) async {
    salvos.add(centro);
    bytes = 2 * 1024 * 1024;
    regiaoSalva.value = (centro: centro, em: DateTime(2026, 11, 22));
    return 0;
  }

  @override
  Future<void> carregarRegiao() async {}

  @override
  Future<int> tamanho() async => bytes;

  @override
  Future<void> limpar() async {
    bytes = 0;
    regiaoSalva.value = null;
  }
}

void main() {
  late MapaOfflineFalso mapa;
  setUp(() {
    mapa = MapaOfflineFalso();
    MapaOfflineService.instance = mapa;
    ConexaoService.instance = ConexaoService();
  });

  test('Região salva é pequena: poucas centenas de partes do mapa', () {
    final pedacos =
        MapaOfflineService.pedacosDaRegiao(const LatLng(-10.95, -37.07));
    // Do zoom 12 ao 16, 3 km em volta: respeita a política do OpenStreetMap.
    expect(pedacos.length, inInclusiveRange(50, 300));
    expect(pedacos.map((p) => p.$1).toSet(), {12, 13, 14, 15, 16});
  });

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro,
      builder: (context, child) => ComFaixaSemInternet(child: child!),
      home: const TelaMapaOffline(),
    ));
    await tester.pump();
  }

  testWidgets('Salvar mapa da região guarda e mostra o espaço usado',
      (tester) async {
    await abrir(tester);
    expect(find.text('Nenhuma ainda'), findsOneWidget);

    await tester.tap(find.text('Salvar mapa da região'));
    await tester.pump();
    await tester.pump();
    expect(mapa.salvos, hasLength(1));
    expect(find.textContaining('Em 22/11/26'), findsOneWidget);
    expect(find.text('2,0 MB'), findsOneWidget);
    expect(find.text('Mapa da região salvo. Ele funciona mesmo sem internet.'),
        findsOneWidget);
  });

  testWidgets('Sem internet: faixa no rodapé e botão de salvar desligado',
      (tester) async {
    await abrir(tester);
    expect(find.byType(FaixaSemInternet), findsNothing);

    ConexaoService.instance.online.value = false;
    await tester.pump();
    expect(find.byType(FaixaSemInternet), findsOneWidget);
    expect(find.text('Conecte-se à internet para salvar o mapa.'),
        findsOneWidget);
    final botao = find.widgetWithText(ElevatedButton, 'Salvar mapa da região');
    expect(tester.widget<ElevatedButton>(botao).onPressed, isNull);

    ConexaoService.instance.online.value = true;
    await tester.pump();
    expect(find.byType(FaixaSemInternet), findsNothing);
  });
}
