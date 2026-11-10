import 'package:flutter_test/flutter_test.dart';

import 'package:enchente_alerta/main.dart';

void main() {
  // O Firebase é inicializado em main(), fora do widget, então o app
  // pode ser montado no teste sem conexão.
  testWidgets('App abre na tela Início com mapa e botões', (tester) async {
    await tester.pumpWidget(const EnchenteAlertaApp());

    expect(find.text('Início'), findsWidgets);
    expect(find.text('Abrigo'), findsOneWidget);
    expect(find.text('Rota de fuga'), findsOneWidget);
    expect(find.text('Hosp. Universitário'), findsOneWidget);
  });

  testWidgets('Barra inferior troca de aba', (tester) async {
    await tester.pumpWidget(const EnchenteAlertaApp());

    await tester.tap(find.text('Avisos'));
    await tester.pump();

    expect(find.text('Em construção'), findsOneWidget);
  });
}
