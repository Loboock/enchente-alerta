import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enchente_alerta/main.dart';
import 'package:enchente_alerta/navegacao.dart';

void main() {
  // O Firebase é inicializado em main(), fora do widget, então o app
  // pode ser montado no teste sem conexão.
  setUp(() => abaAtual.value = 0);

  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(const EnchenteAlertaApp());
  }

  // A troca de tela precisa de um quadro para começar e de tempo para terminar.
  Future<void> esperar(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('App abre na tela Início com mapa e botões', (tester) async {
    await abrirApp(tester);

    expect(find.text('Início'), findsWidgets);
    expect(find.text('Abrigo'), findsOneWidget);
    expect(find.text('Rota de fuga'), findsOneWidget);
    expect(find.text('Hosp. Universitário'), findsOneWidget);
  });

  testWidgets('Barra inferior troca de aba', (tester) async {
    await abrirApp(tester);

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

  testWidgets('Abrigo lista os abrigos e abre a rota ao tocar em um',
      (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Abrigo'));
    await esperar(tester);

    expect(find.text('Abrigos próximos'), findsOneWidget);
    expect(find.text('Esc. Gonçalo Rollemberg Leite'), findsOneWidget);
    expect(find.text('630 m'), findsOneWidget);
    expect(find.text('Ginásio Fernando Collor'), findsOneWidget);
    expect(find.text('1,2 km'), findsOneWidget);

    await tester.tap(find.text('Esc. Gonçalo Rollemberg Leite'));
    await esperar(tester);

    expect(find.text('Menor risco até o abrigo'), findsOneWidget);
    expect(find.text('Iniciar navegação'), findsOneWidget);
  });

  testWidgets('Rota de fuga pede o destino e depois mostra a rota',
      (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Rota de fuga'));
    await esperar(tester);

    expect(find.text('Escolha para onde ir'), findsOneWidget);

        // Na tela pequena do teste o cartão fica abaixo da dobra: rola até ele.
    await tester.ensureVisible(find.text('Colégio Arquidiocesano'));
    await tester.pump();
    await tester.tap(find.text('Colégio Arquidiocesano'));
    await esperar(tester);

    expect(find.text('Menor risco até o abrigo'), findsOneWidget);
    expect(find.text('950m'), findsWidgets);
    expect(find.text('13 min'), findsOneWidget);
    expect(find.text('4 min'), findsOneWidget);
    expect(find.text('Iniciar navegação'), findsOneWidget);
  });

  testWidgets('Busca de destino ignora acento e maiúscula', (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Rota de fuga'));
    await esperar(tester);

    await tester.enterText(find.byType(TextField), 'GINASIO');
    await tester.pump();

    expect(find.text('Ginásio Fernando Collor'), findsOneWidget);
    expect(find.text('Escola Exemplo'), findsNothing);

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();

    expect(find.text('Nenhum local encontrado'), findsOneWidget);
  });

  testWidgets('Barra inferior das telas abertas leva de volta às abas',
      (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Abrigo'));
    await esperar(tester);

    await tester.tap(find.text('Perfil'));
    await esperar(tester);

    expect(find.text('Abrigos próximos'), findsNothing);
    expect(find.text('Cadastrar-se'), findsOneWidget);
  });

  testWidgets('Aba Histórico lista os alagamentos, do mais recente ao mais antigo',
      (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Histórico'));
    await tester.pump();

    expect(find.text('Últimos alagamentos na sua região'), findsOneWidget);
    expect(find.text('Av. Ivo do Prado, Centro'), findsOneWidget);
    expect(find.text('Grave · 80 cm · 18/09/26'), findsOneWidget);
    expect(find.text('Moderado · 35 cm · 11/07/26'), findsOneWidget);
  });

  testWidgets('Aba Guia mostra as orientações e os telefones de emergência',
      (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Guia'));
    await tester.pump();

    expect(find.text('Antes, durante e depois'), findsOneWidget);
    expect(find.text('Acompanhe os alertas da Defesa Civil'), findsOneWidget);
    expect(find.text('Se precisar evacuar'), findsOneWidget);

    // A seção de emergência fica abaixo da dobra na tela pequena do teste.
    await tester.scrollUntilVisible(find.text('Defesa civil 199'), 200);
    expect(find.text('SAMU 192'), findsOneWidget);
    expect(find.text('Bombeiros 193'), findsOneWidget);
  });

  testWidgets('Botão de ajuda abre a tela Ajuda e os itens levam às telas',
      (tester) async {
    await abrirApp(tester);

    await tester.tap(find.byTooltip('Ajuda'));
    await esperar(tester);

    expect(find.text('Abrigos próximos'), findsOneWidget);

    await tester.tap(find.text('Abrigos próximos'));
    await esperar(tester);

    expect(find.text('Ordenado por distância'), findsOneWidget);
  });

  testWidgets('Item da Ajuda volta para a aba escolhida', (tester) async {
    await abrirApp(tester);

    await tester.tap(find.byTooltip('Ajuda'));
    await esperar(tester);

    await tester.scrollUntilVisible(find.text('Guia de segurança'), 200);
    await tester.tap(find.text('Guia de segurança'));
    await esperar(tester);

    expect(abaAtual.value, 4);
    expect(find.text('Antes, durante e depois'), findsOneWidget);
  });
}
