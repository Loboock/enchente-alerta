import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enchente_alerta/data/dados_provisorios.dart';
import 'package:enchente_alerta/main.dart';
import 'package:enchente_alerta/models/models.dart';
import 'package:enchente_alerta/models/perigo.dart';
import 'package:enchente_alerta/navegacao.dart';
import 'package:enchente_alerta/services/localizacao_service.dart';
import 'package:enchente_alerta/services/perigos_service.dart';
import 'package:enchente_alerta/services/rotas_service.dart';

import 'package:enchente_alerta/widgets/mapa/mapa_enchente.dart';

import 'fakes.dart';

void main() {
  // O Firebase é inicializado em main(), fora do widget, então o app
  // pode ser montado no teste sem conexão. GPS e rotas são trocados por
  // versões falsas (test/fakes.dart), sem internet.
  late RotasFalsas rotas;
  setUp(() {
    abaAtual.value = 0;
    LocalizacaoService.instance = LocalizacaoFalsa();
    rotas = RotasFalsas();
    RotasService.instance = rotas;
  });

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

    expect(
      find.text('Menor risco até Esc. Gonçalo Rollemberg Leite'),
      findsOneWidget,
    );
    expect(find.text('Iniciar navegação'), findsOneWidget);
  });

  // A busca espera a pessoa parar de digitar antes de chamar o serviço.
  Future<void> buscar(WidgetTester tester, String texto) async {
    await tester.enterText(find.byType(TextField), texto);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  testWidgets('Rota de fuga busca o endereço e depois mostra a rota',
      (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Rota de fuga'));
    await esperar(tester);

    expect(find.text('Para onde você quer ir?'), findsOneWidget);

    await buscar(tester, 'Rua Teste');
    expect(find.text('Rua Teste, Farolândia, Aracaju'), findsOneWidget);

    // O texto "Rua Teste" também está no campo de busca: toca no endereço.
    await tester.tap(find.text('Rua Teste, Farolândia, Aracaju'));
    await esperar(tester);

    expect(find.text('Menor risco até Rua Teste'), findsOneWidget);
    expect(find.text('950m'), findsOneWidget);
    expect(find.text('4 min'), findsOneWidget);
    expect(find.text('Iniciar navegação'), findsOneWidget);

    // Trocar para "A pé" calcula de novo com o outro perfil.
    await tester.tap(find.text('A pé'));
    await esperar(tester);

    expect(find.text('13 min'), findsOneWidget);
    expect(rotas.pedidos.map((p) => p.modo.rotulo), ['De carro', 'A pé']);
  });

  testWidgets('Busca de endereço sem resultado mostra aviso', (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Rota de fuga'));
    await esperar(tester);

    // Menos de 3 letras: só a orientação, sem buscar.
    await buscar(tester, 'xy');
    expect(find.textContaining('Digite o endereço'), findsOneWidget);

    await buscar(tester, 'xyz');
    expect(find.textContaining('Nenhum endereço encontrado'), findsOneWidget);
  });

  testWidgets('Iniciar navegação abre a tela curva a curva', (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Abrigo'));
    await esperar(tester);
    await tester.tap(find.text('Esc. Gonçalo Rollemberg Leite'));
    await esperar(tester);

    await tester.tap(find.text('Iniciar navegação'));
    await esperar(tester);

    expect(find.textContaining('Chegada'), findsOneWidget);
    expect(find.text('Você chegou'), findsOneWidget);
    expect(find.byTooltip('Encerrar navegação'), findsOneWidget);

    await tester.tap(find.byTooltip('Encerrar navegação'));
    await esperar(tester);

    expect(find.text('Iniciar navegação'), findsOneWidget);
  });

  testWidgets('Reportar sem conta pede para entrar', (tester) async {
    await abrirApp(tester);

    await tester.tap(find.byTooltip('Reportar alagamento'));
    await tester.pump();

    expect(find.text('Entre na sua conta para enviar avisos.'), findsOneWidget);
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

  testWidgets('Aviso na posição do usuário abre ao tocar no ponto azul',
      (tester) async {
    // Quem reporta onde está fica com o aviso embaixo do próprio ponto.
    final agora = DateTime.now();
    PerigosService.instance = PerigosService();
    PerigosService.instance.perigos.value = [
      Perigo.daOcorrencia(Ocorrencia(
        id: 'oc1',
        tipo: TipoOcorrencia.alagamento,
        gravidade: Gravidade.grave,
        endereco: 'Farolândia',
        localizacao: usuarioProvisorio,
        nivelAguaCm: 40,
        criadaEm: agora,
        expiraEm: agora.add(const Duration(hours: 4)),
      )),
    ];
    await abrirApp(tester);
    await esperar(tester);

    // O toque atravessa o ponto azul (IgnorePointer) e chega no aviso.
    await tester.tap(find.byType(MarcadorUsuario).first, warnIfMissed: false);
    await esperar(tester);

    expect(find.text('Ainda está aí'), findsOneWidget);
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
