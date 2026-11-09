import 'package:flutter_test/flutter_test.dart';

import 'package:enchente_alerta/main.dart';

void main() {
  // O Firebase é inicializado em main(), fora do widget, então o app
  // pode ser montado no teste sem conexão.
  testWidgets('App abre a tela inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const EnchenteAlertaApp());

    expect(find.text('EnchenteAlerta'), findsOneWidget);
    expect(find.text('Informação que te protege'), findsOneWidget);
  });
}
