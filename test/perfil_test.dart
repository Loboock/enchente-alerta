import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enchente_alerta/models/models.dart';
import 'package:enchente_alerta/screens/conta/tela_meus_dados.dart';
import 'package:enchente_alerta/screens/conta/tela_perfil.dart';
import 'package:enchente_alerta/theme/app_theme.dart';

void main() {
  Future<void> abrir(WidgetTester tester, Widget tela) async {
    // Tela alta: tudo cabe sem rolar.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.claro, home: tela));
  }

  testWidgets('Perfil do morador mostra só o nome, sem o e-mail',
      (tester) async {
    var meusDados = 0;
    bool? notificacoes;
    await abrir(
      tester,
      PerfilMorador(
        nome: 'Lucas',
        notificacoesAtivas: true,
        aoMeusDados: () => meusDados++,
        aoMudarNotificacoes: (v) => notificacoes = v,
        aoEnderecoPadrao: () {},
        aoSair: () {},
      ),
    );

    expect(find.text('Lucas'), findsOneWidget);
    expect(find.text('L'), findsOneWidget); // inicial no avatar
    expect(find.textContaining('@'), findsNothing);
    expect(find.text('Meus dados'), findsOneWidget);
    expect(find.text('Endereço padrão'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);

    await tester.tap(find.text('Meus dados'));
    expect(meusDados, 1);

    await tester.tap(find.byType(Switch));
    expect(notificacoes, isFalse);
  });

  testWidgets('Meus dados mostra e-mail e conta, e salva só o nome alterado',
      (tester) async {
    final salvos = <String>[];
    await abrir(
      tester,
      TelaMeusDados(
        nome: 'Lucas',
        email: 'lucas@exemplo.com',
        perfil: PerfilUsuario.morador,
        criadaEm: DateTime(2026, 11, 15),
        aoSalvarNome: (nome) async => salvos.add(nome),
        aoAlterarSenha: () async {},
      ),
    );

    expect(find.text('lucas@exemplo.com'), findsOneWidget);
    expect(find.text('Morador'), findsOneWidget);
    expect(find.text('15 de novembro de 2026'), findsOneWidget);

    // Sem mudança, "Salvar alterações" fica desligado.
    final salvar = find.widgetWithText(ElevatedButton, 'Salvar alterações');
    expect(tester.widget<ElevatedButton>(salvar).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('campo-nome')), '');
    await tester.pump();
    await tester.tap(salvar);
    await tester.pump();
    expect(find.text('Informe o seu nome.'), findsOneWidget);
    expect(salvos, isEmpty);

    await tester.enterText(
        find.byKey(const Key('campo-nome')), '  Lucas Souza ');
    await tester.pump();
    await tester.tap(salvar);
    await tester.pump();
    expect(salvos, ['Lucas Souza']);
    expect(find.text('Dados atualizados.'), findsOneWidget);
  });

  testWidgets('Alterar senha confirma e envia o link', (tester) async {
    var enviados = 0;
    await abrir(
      tester,
      TelaMeusDados(
        nome: 'Lucas',
        email: 'lucas@exemplo.com',
        perfil: PerfilUsuario.morador,
        aoSalvarNome: (_) async {},
        aoAlterarSenha: () async => enviados++,
      ),
    );

    await tester.tap(find.text('Alterar senha'));
    await tester.pump();
    expect(find.textContaining('lucas@exemplo.com um link'), findsOneWidget);
    await tester.tap(find.text('Enviar link'));
    await tester.pump();
    await tester.pump();
    expect(enviados, 1);
    expect(find.text('Link enviado. Confira o seu e-mail.'), findsOneWidget);
  });
}
