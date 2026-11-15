import 'package:flutter/material.dart';
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

  testWidgets('Visitante abre a aba Perfil e vê o login, sem precisar de conta',
      (tester) async {
    await tester.pumpWidget(const EnchenteAlertaApp());

    await tester.tap(find.text('Perfil'));
    await tester.pump();

    expect(find.text('Cadastrar-se'), findsOneWidget);
    expect(find.text('Esqueceu a senha?'), findsOneWidget);
  });

  testWidgets('Login valida os campos antes de chamar o Firebase',
      (tester) async {
    await tester.pumpWidget(const EnchenteAlertaApp());

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    final botaoEntrar = find.widgetWithText(ElevatedButton, 'Entrar');
    await tester.ensureVisible(botaoEntrar);
    await tester.tap(botaoEntrar);
    await tester.pump();

    expect(find.text('Informe o e-mail'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
  });
}
