import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enchente_alerta/data/dados_provisorios.dart';
import 'package:enchente_alerta/main.dart';
import 'package:enchente_alerta/models/models.dart';
import 'package:enchente_alerta/models/perigo.dart';
import 'package:enchente_alerta/screens/avisos/tela_criar_aviso.dart';
import 'package:enchente_alerta/screens/avisos/tela_reportar_aviso.dart';
import 'package:enchente_alerta/navegacao.dart';
import 'package:enchente_alerta/services/abrigos_service.dart';
import 'package:enchente_alerta/services/alertas_service.dart';
import 'package:enchente_alerta/services/historico_service.dart';
import 'package:enchente_alerta/services/localizacao_service.dart';
import 'package:enchente_alerta/services/perigos_service.dart';
import 'package:enchente_alerta/services/rotas_fuga_service.dart';
import 'package:enchente_alerta/services/rotas_service.dart';
import 'package:enchente_alerta/theme/app_theme.dart';
import 'package:enchente_alerta/theme/modo_tema.dart';
import 'package:enchente_alerta/utils/formatacao.dart';
import 'package:enchente_alerta/widgets/mapa/mapa_enchente.dart';

import 'fakes.dart';

void main() {
  // O Firebase é inicializado em main(), fora do widget, então o app
  // pode ser montado no teste sem conexão. GPS e rotas são trocados por
  // versões falsas (test/fakes.dart), sem internet.
  late RotasFalsas rotas;
  setUp(() {
    abaAtual.value = 0;
    ModoTema.instance.modo.value = ThemeMode.system;
    RotasFugaService.instance = RotasFugaService();
    LocalizacaoService.instance = LocalizacaoFalsa();
    rotas = RotasFalsas();
    RotasService.instance = rotas;
    PerigosService.instance = PerigosService();
    AbrigosService.instance = AbrigosService();
    AlertasService.instance = AlertasService();
    HistoricoService.instance = HistoricoService();
  });

  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(const EnchenteAlertaApp());
  }

  // A troca de tela precisa de um quadro para começar e de tempo para terminar.
  Future<void> esperar(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('Botão do Início troca entre modo claro e escuro',
      (tester) async {
    await abrirApp(tester);
    Brightness tema() =>
        Theme.of(tester.element(find.byType(BotaoModoTema))).brightness;
    ThemeMode modoDoApp() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

    // O aparelho do teste está no claro: o botão oferece o escuro.
    expect(tema(), Brightness.light);
    await tester.tap(find.byTooltip('Ativar modo escuro'));
    await esperar(tester);
    expect(tema(), Brightness.dark);
    expect(modoDoApp(), ThemeMode.dark);

    await tester.tap(find.byTooltip('Ativar modo claro'));
    await esperar(tester);
    expect(tema(), Brightness.light);

    // O botão de tema só fica no Início.
    await tester.tap(find.text('Guia'));
    await tester.pump();
    expect(find.byTooltip('Ativar modo escuro').hitTestable(), findsNothing);
  });

  testWidgets('App abre na tela Início com mapa e botões', (tester) async {
    await abrirApp(tester);

    expect(find.text('Início'), findsWidgets);
    expect(find.text('Abrigo'), findsOneWidget);
    expect(find.text('Rota de fuga'), findsOneWidget);
  });

  testWidgets('Atalhos do Início mostram os abrigos mais próximos e abrem a rota',
      (tester) async {
    // Rota oficial da Defesa Civil até o abrigo mais próximo.
    RotasFugaService.instance = RotasFugaService()
      ..rotas.value = [
        RotasFugaService.montar(
          id: 'r1',
          abrigoId: 'ab1',
          pontos: [usuarioProvisorio, abrigosDeExemplo.first.localizacao],
          riscoNaVia: Gravidade.leve,
          interditada: false,
        ),
      ];
    await abrirApp(tester);
    await esperar(tester);

    // O mais próximo dos abrigos de exemplo (630 m).
    final atalho = find.text('Esc. Gonçalo Rollemberg Leite');
    expect(atalho, findsOneWidget);
    await tester.tap(atalho);
    await esperar(tester);

    expect(find.text('Menor risco até Esc. Gonçalo Rollemberg Leite'),
        findsOneWidget);
    expect(find.textContaining('Rota oficial da Defesa Civil até o abrigo'),
        findsOneWidget);
  });

  test('Endereço curto tira cidade, estado e país, como no protótipo', () {
    expect(encurtarEndereco('Condomínio Arte Viva, Aracaju, SE, Brasil'),
        'Condomínio Arte Viva');
    expect(encurtarEndereco('Av. Ivo do Prado, Centro'),
        'Av. Ivo do Prado, Centro');
    expect(encurtarEndereco('Rua A, Farolândia, Aracaju, SE, Brasil'),
        'Rua A, Farolândia');
    expect(encurtarEndereco('Aracaju'), 'Aracaju');
  });

  testWidgets('Barra inferior troca de aba', (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Avisos'));
    await tester.pump();

    expect(find.text('Avisos de alagamento'), findsOneWidget);
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
  // [campo]: 'campo-destino' (padrão) ou 'campo-partida'.
  Future<void> buscar(WidgetTester tester, String texto,
      {String campo = 'campo-destino'}) async {
    await tester.enterText(find.byKey(Key(campo)), texto);
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

    // Cancelar volta para a escolha, com o destino ainda preenchido.
    await tester.tap(find.text('Cancelar'));
    await esperar(tester);
    expect(find.text('Menor risco até Rua Teste'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('campo-destino')),
        matching: find.text('Rua Teste'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Com GPS a partida vem preenchida e pode ser trocada',
      (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Rota de fuga'));
    await esperar(tester);

    // Partida em cima do destino, já com a localização atual.
    expect(find.text('Sua localização'), findsOneWidget);
    final yPartida = tester.getTopLeft(find.byKey(const Key('campo-partida'))).dy;
    final yDestino = tester.getTopLeft(find.byKey(const Key('campo-destino'))).dy;
    expect(yPartida, lessThan(yDestino));

    // Troca a partida por um endereço.
    await buscar(tester, 'Rua Teste', campo: 'campo-partida');
    await tester.tap(find.text('Rua Teste, Farolândia, Aracaju'));
    await esperar(tester);
    expect(find.text('Sua localização'), findsNothing);

    await buscar(tester, 'Rua Teste');
    await tester.tap(find.text('Rua Teste, Farolândia, Aracaju'));
    await esperar(tester);

    expect(find.text('Menor risco até Rua Teste'), findsOneWidget);

    // Partida trocada: a navegação existe, mas passo a passo.
    await tester.tap(find.text('Iniciar navegação'));
    await esperar(tester);
    expect(find.text('Sem GPS: passo 1 de 2'), findsOneWidget);
    expect(find.text('Siga para o norte'), findsNothing); // é o passo atual
    expect(find.text('Você chegou'), findsOneWidget); // próxima manobra

    await tester.tap(find.text('Próxima'));
    await esperar(tester);
    expect(find.text('Sem GPS: passo 2 de 2'), findsOneWidget);

    await tester.tap(find.text('Próxima'));
    await esperar(tester);
    expect(find.text('Você chegou em Rua Teste'), findsOneWidget);
  });

  testWidgets('Sem GPS a rota pede o ponto de partida antes de calcular',
      (tester) async {
    // Permissão negada: o serviço cai na posição de exemplo.
    LocalizacaoService.instance.posicao.value = const PosicaoUsuario.teste();
    await abrirApp(tester);

    await tester.tap(find.text('Rota de fuga'));
    await esperar(tester);
    expect(find.text('Sem localização: digite a partida'), findsOneWidget);

    await buscar(tester, 'Rua Teste');
    await tester.tap(find.text('Rua Teste, Farolândia, Aracaju'));
    await esperar(tester);

    // Ainda não calculou: pede a partida.
    expect(find.text('Sem localização. Escolha de onde você vai sair.'),
        findsOneWidget);
    expect(rotas.pedidos, isEmpty);

    await buscar(tester, 'Rua Teste', campo: 'campo-partida');
    await tester.tap(find.text('Rua Teste, Farolândia, Aracaju'));
    await esperar(tester);

    expect(find.text('Menor risco até Rua Teste'), findsOneWidget);
    expect(rotas.pedidos, hasLength(1));

    // Sem conta e sem GPS a navegação também abre (passo a passo).
    // Espera o aviso de baixo sumir: ele cobre o botão.
    await tester.pump(const Duration(seconds: 5));
    await esperar(tester);
    await tester.tap(find.text('Iniciar navegação'));
    await esperar(tester);
    expect(find.text('Próxima'), findsOneWidget);
    expect(find.text('Anterior'), findsOneWidget);
  });

  testWidgets('Ajuda "i" da aba mostra o texto dela e leva à Ajuda completa',
      (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Guia'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.info_outline).hitTestable());
    await esperar(tester);

    expect(find.textContaining('telefones de emergência'), findsOneWidget);

    await tester.tap(find.text('Ver ajuda completa'));
    await esperar(tester);

    // Tela Ajuda: índice das telas.
    expect(find.text('Abrigos próximos'), findsOneWidget);
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

    expect(find.text('Ainda alagado'), findsOneWidget);
  });

  Ocorrencia registro(String id, String endereco, DateTime criadaEm,
          {StatusOcorrencia status = StatusOcorrencia.resolvida,
          Duration duracao = const Duration(hours: 6),
          TipoOcorrencia tipo = TipoOcorrencia.alagamento,
          Gravidade gravidade = Gravidade.grave,
          int nivel = 80}) =>
      Ocorrencia(
        id: id,
        tipo: tipo,
        gravidade: gravidade,
        status: status,
        endereco: endereco,
        localizacao: usuarioProvisorio,
        nivelAguaCm: nivel,
        criadaEm: criadaEm,
        expiraEm: criadaEm.add(duracao),
      );

  testWidgets('Aba Histórico mostra os registros do Firestore com a situação',
      (tester) async {
    final agora = DateTime.now();
    // Vem do Firestore já em ordem decrescente de criadaEm.
    HistoricoService.instance.ocorrencias.value = [
      registro('a', 'Rua Ativa, Centro', agora,
          status: StatusOcorrencia.ativa, nivel: 40,
          gravidade: Gravidade.moderado),
      registro('v', 'Rua Vencida, Atalaia', DateTime(2026, 9, 18),
          status: StatusOcorrencia.ativa),
      registro('o', 'Av. Obstruída, Jardins', DateTime(2026, 8, 2),
          tipo: TipoOcorrencia.viaObstruida, nivel: 0),
      registro('r', 'Av. Ivo do Prado, Centro', DateTime(2026, 7, 11)),
    ];
    await abrirApp(tester);

    await tester.tap(find.text('Histórico'));
    await tester.pump();

    expect(find.text('Últimos alagamentos na sua região'), findsOneWidget);
    expect(find.text('4 registros'), findsOneWidget);
    expect(find.text('Rua Ativa, Centro'), findsOneWidget);
    expect(find.text('Ativo agora'), findsOneWidget);
    // ATIVA com o prazo vencido conta como expirado (expiração feita no app).
    expect(find.text('Grave · 80 cm · 18/09/26'), findsOneWidget);
    expect(find.text('Expirado'), findsOneWidget);
    expect(find.text('Via obstruída · Grave · 02/08/26'), findsOneWidget);
    expect(find.text('Resolvido'), findsNWidgets(2));
  });

  testWidgets('Histórico sem registros e com erro de conexão', (tester) async {
    await abrirApp(tester);
    await tester.tap(find.text('Histórico'));
    await tester.pump();
    // Sem Firebase no teste, a consulta devolve a lista vazia.
    expect(find.text('Nenhum alagamento registrado na sua região.'),
        findsOneWidget);

    HistoricoService.instance.erro.value = 'Não foi possível carregar.';
    await tester.pump();
    expect(find.text('Não foi possível carregar.'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('Aba Guia mostra as orientações e os telefones de emergência',
      (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Guia'));
    await tester.pump();

    expect(find.text('Antes, durante e depois'), findsOneWidget);
    expect(find.text('Salve o mapa da região'), findsOneWidget);
    expect(find.text('Acompanhe os alertas da Defesa Civil'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Se precisar evacuar'), 200);

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

  // ---------- Avisos, Criar aviso e Reportar aviso ----------

  Ocorrencia aviso(String id, String endereco, Gravidade gravidade,
          int nivelAguaCm, Duration atras) {
    final criadaEm = DateTime.now().subtract(atras);
    return Ocorrencia(
      id: id,
      tipo: TipoOcorrencia.alagamento,
      gravidade: gravidade,
      endereco: endereco,
      localizacao: usuarioProvisorio,
      nivelAguaCm: nivelAguaCm,
      criadaEm: criadaEm,
      expiraEm: criadaEm.add(const Duration(hours: 4)),
    );
  }

  Future<void> abrirTela(WidgetTester tester, Widget tela) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.claro, home: tela));
    await tester.pump();
  }

  testWidgets('Aba Avisos lista os avisos ativos, do mais recente ao mais antigo',
      (tester) async {
    PerigosService.instance.perigos.value = [
      Perigo.daOcorrencia(
          aviso('a', 'Av. Principal, Siqueira Campos', Gravidade.moderado, 30,
              const Duration(minutes: 25))),
      Perigo.daOcorrencia(aviso('b', 'Rua Exemplo, Centro', Gravidade.grave,
          80, const Duration(minutes: 10))),
    ];
    await abrirApp(tester);

    await tester.tap(find.text('Avisos'));
    await tester.pump();

    expect(find.text('ALAGAMENTO GRAVE'), findsOneWidget);
    expect(find.text('Água a 80 cm · há 10 min'), findsOneWidget);
    expect(find.text('Água a 30 cm · há 25 min'), findsOneWidget);
    expect(find.text('Reportar'), findsNWidgets(2));
    // O mais recente vem primeiro.
    expect(
      tester.getTopLeft(find.text('Rua Exemplo, Centro')).dy,
      lessThan(tester.getTopLeft(find.text('Av. Principal, Siqueira Campos')).dy),
    );
    // Visitante não é autor de nenhum aviso: não vê Excluir.
    expect(find.text('Excluir'), findsNothing);
  });

  testWidgets('Aba Avisos sem avisos ativos mostra mensagem e Criar aviso',
      (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text('Avisos'));
    await tester.pump();

    expect(find.text('Nenhum aviso de alagamento ativo agora.'), findsOneWidget);
    expect(find.text('Criar aviso'), findsOneWidget);
  });

  testWidgets('Criar e reportar aviso sem conta pedem para entrar',
      (tester) async {
    PerigosService.instance.perigos.value = [
      Perigo.daOcorrencia(aviso('b', 'Rua Exemplo, Centro', Gravidade.grave,
          80, const Duration(minutes: 10))),
    ];
    await abrirApp(tester);
    await tester.tap(find.text('Avisos'));
    await tester.pump();

    await tester.tap(find.text('Criar aviso'));
    await tester.pump();
    expect(find.text('Entre na sua conta para criar avisos.'), findsOneWidget);

    await tester.tap(find.text('Reportar'));
    await tester.pump();
    expect(find.text('Entre na sua conta para reportar avisos.'), findsOneWidget);
  });

  testWidgets('Criar aviso valida gravidade, endereço e nível da água',
      (tester) async {
    await abrirTela(tester, const TelaCriarAviso());

    await tester.ensureVisible(find.text('Criar'));
    await tester.pump();
    await tester.tap(find.text('Criar'));
    await tester.pump();

    expect(find.text('Escolha a gravidade.'), findsOneWidget);
    expect(find.text('Informe o endereço.'), findsOneWidget);
    expect(find.text('Informe o nível da água em cm.'), findsOneWidget);

    await tester.ensureVisible(find.bySemanticsLabel('Gravidade Grave'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Gravidade Grave'));
    await tester.enterText(find.byType(TextFormField).at(1), '600');
    await tester.ensureVisible(find.text('Criar'));
    await tester.pump();
    await tester.tap(find.text('Criar'));
    await tester.pump();

    expect(find.text('Escolha a gravidade.'), findsNothing);
    expect(find.text('Use um valor de 0 a 500 cm.'), findsOneWidget);
  });

  testWidgets('Reportar aviso mostra o aviso e os 4 motivos do protótipo',
      (tester) async {
    await abrirTela(
      tester,
      TelaReportarAviso(
        ocorrencia: aviso('b', 'Rua Exemplo, Centro', Gravidade.grave, 80,
            const Duration(minutes: 10)),
      ),
    );

    expect(find.text('Rua Exemplo, Centro · Alagamento grave'), findsOneWidget);
    expect(find.text('Informação incorreta'), findsOneWidget);
    expect(find.text('Água já baixou / não existe mais'), findsOneWidget);
    expect(find.text('Localização errada no mapa'), findsOneWidget);
    expect(find.text('Spam ou conteúdo abusivo'), findsOneWidget);

    // Sem conta, o envio é recusado com mensagem em português.
    await tester.tap(find.text('Água já baixou / não existe mais'));
    await tester.ensureVisible(find.text('Enviar denúncia'));
    await tester.pump();
    await tester.tap(find.text('Enviar denúncia'));
    await tester.pump();
    expect(find.text('Entre na sua conta para enviar avisos.'), findsOneWidget);
  });
}
