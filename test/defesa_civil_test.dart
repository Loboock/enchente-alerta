import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:enchente_alerta/data/dados_provisorios.dart';
import 'package:enchente_alerta/main.dart';
import 'package:enchente_alerta/models/models.dart';
import 'package:enchente_alerta/models/perigo.dart';
import 'package:enchente_alerta/navegacao.dart';
import 'package:enchente_alerta/screens/defesa_civil/tela_abrigos_defesa_civil.dart';
import 'package:enchente_alerta/screens/defesa_civil/tela_alertas_defesa_civil.dart';
import 'package:enchente_alerta/screens/defesa_civil/tela_painel_defesa_civil.dart';
import 'package:enchente_alerta/services/abrigos_service.dart';
import 'package:enchente_alerta/services/alertas_service.dart';
import 'package:enchente_alerta/services/defesa_civil_service.dart';
import 'package:enchente_alerta/services/localizacao_service.dart';
import 'package:enchente_alerta/services/perigos_service.dart';
import 'package:enchente_alerta/services/rotas_service.dart';
import 'package:enchente_alerta/theme/app_theme.dart';

import 'fakes.dart';
import 'fakes_defesa_civil.dart';

void main() {
  late AbrigosFalsos abrigos;
  late AlertasFalsos alertas;
  late DefesaCivilFalsa defesaCivil;

  final agora = DateTime.now();

  final aviso = Ocorrencia(
    id: 'oc1',
    tipo: TipoOcorrencia.alagamento,
    gravidade: Gravidade.grave,
    endereco: 'Av. Beira Mar, Atalaia',
    localizacao: usuarioProvisorio,
    nivelAguaCm: 60,
    criadaEm: agora.subtract(const Duration(minutes: 30)),
    expiraEm: agora.add(const Duration(hours: 3)),
  );

  Alerta alertaAtivo({String titulo = 'Chuva forte nas próximas 3 horas'}) =>
      Alerta(
        id: 'al1',
        titulo: titulo,
        descricao: 'Evite a Av. Beira Mar',
        nivel: Gravidade.grave,
        origem: OrigemAlerta.meteorologica,
        emitidoEm: agora.subtract(const Duration(minutes: 10)),
        expiraEm: agora.add(const Duration(hours: 2)),
      );

  setUp(() {
    abaAtual.value = 0;
    LocalizacaoService.instance = LocalizacaoFalsa();
    RotasService.instance = RotasFalsas();
    PerigosService.instance = PerigosService();
    AbrigosService.instance = abrigos = AbrigosFalsos();
    AlertasService.instance = alertas = AlertasFalsos();
    DefesaCivilService.instance = defesaCivil = DefesaCivilFalsa();
  });

  Future<void> abrir(WidgetTester tester, Widget tela) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.claro, home: tela));
  }

  Future<void> esperar(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('Painel da Defesa Civil resume denúncias, alertas e abrigos',
      (tester) async {
    defesaCivil.pendentes.value = [
      GrupoDenuncias(ocorrenciaId: 'oc1', denuncias: [
        Denuncia(
            id: 'bia',
            autorId: 'bia',
            motivo: MotivoDenuncia.aguaBaixou,
            criadaEm: agora),
      ]),
    ];
    alertas.alertas.value = [alertaAtivo()];
    abrigos.cadastrados.value = abrigosDeExemplo.take(2).toList();

    await abrir(
      tester,
      TelaPainelDefesaCivil(
        nome: 'Defesa Civil Aracaju',
        aoEditarDados: () {},
        aoSair: () {},
      ),
    );

    expect(find.text('Painel da Defesa Civil'), findsOneWidget);
    expect(find.text('DEFESA CIVIL'), findsOneWidget);
    expect(find.text('1 aviso para revisar'), findsOneWidget);
    expect(find.text('1 alerta ativo agora'), findsOneWidget);
    expect(find.text('2 abrigos cadastrados'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sair'), 200);
    expect(find.text('Meus dados'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
  });

  testWidgets('Denúncias: Defesa Civil resolve o aviso denunciado',
      (tester) async {
    PerigosService.instance.perigos.value = [Perigo.daOcorrencia(aviso)];
    defesaCivil.pendentes.value = [
      GrupoDenuncias(ocorrenciaId: 'oc1', denuncias: [
        Denuncia(
            id: 'bia',
            autorId: 'bia',
            motivo: MotivoDenuncia.aguaBaixou,
            detalhes: 'Já dá para passar',
            criadaEm: agora),
      ]),
    ];

    await abrir(
      tester,
      TelaPainelDefesaCivil(
        nome: 'DC',
        aoEditarDados: () {},
        aoSair: () {},
      ),
    );
    await tester.tap(find.text('Denúncias'));
    await esperar(tester);

    expect(find.text('1 DENÚNCIA'), findsOneWidget);
    expect(find.text('Av. Beira Mar, Atalaia'), findsOneWidget);
    expect(find.textContaining('Água já baixou'), findsOneWidget);
    expect(find.textContaining('Já dá para passar'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Resolver'));
    await tester.pump();
    expect(find.text('Resolver aviso?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Resolver'));
    await esperar(tester);

    expect(defesaCivil.resolvidos, ['oc1']);
    expect(find.text('Nenhuma denúncia pendente.'), findsOneWidget);
  });

  testWidgets('Denúncia de aviso que já acabou só pode ser arquivada',
      (tester) async {
    defesaCivil.pendentes.value = [
      GrupoDenuncias(ocorrenciaId: 'antigo', denuncias: [
        Denuncia(
            id: 'bia',
            autorId: 'bia',
            motivo: MotivoDenuncia.spamOuAbuso,
            criadaEm: agora),
      ]),
    ];
    await abrir(
      tester,
      TelaPainelDefesaCivil(
          nome: 'DC', aoEditarDados: () {}, aoSair: () {}),
    );
    await tester.tap(find.text('Denúncias'));
    await esperar(tester);

    expect(find.text('Aviso já encerrado ou excluído'), findsOneWidget);
    expect(find.text('Resolver'), findsNothing);
    await tester.tap(find.text('Arquivar denúncias'));
    await esperar(tester);
    expect(defesaCivil.mantidos, ['antigo']);
  });

  testWidgets('Emitir alerta valida o título e salva com nível e validade',
      (tester) async {
    // Tela alta: o formulário inteiro cabe sem rolar.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await abrir(tester, const TelaAlertasDefesaCivil());
    expect(find.text('Nenhum alerta ativo agora.'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Emitir alerta'));
    await esperar(tester);

    final emitir = find.widgetWithText(ElevatedButton, 'Emitir alerta');
    await tester.ensureVisible(emitir);
    await tester.tap(emitir);
    await tester.pump();
    expect(find.text('Informe o título do alerta.'), findsOneWidget);
    expect(alertas.salvos, isEmpty);

    await tester.ensureVisible(find.text('Grave'));
    await tester.tap(find.text('Grave'));
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('campo-titulo-alerta')), 'Chuva forte hoje');
    await tester.tap(emitir);
    await esperar(tester);

    expect(alertas.salvos, hasLength(1));
    final salvo = alertas.salvos.single;
    expect(salvo.titulo, 'Chuva forte hoje');
    expect(salvo.nivel, Gravidade.grave);
    expect(salvo.expiraEm.difference(salvo.emitidoEm).inHours, 6);
    // Voltou para a lista, agora com o alerta ativo.
    expect(find.text('Ativos (1)'), findsOneWidget);
    expect(find.text('Chuva forte hoje'), findsOneWidget);
  });

  testWidgets('Novo abrigo exige local e vagas até a capacidade',
      (tester) async {
    await abrir(tester, const TelaAbrigosDefesaCivil());
    expect(find.text('Cadastrar os abrigos de exemplo'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Novo abrigo'));
    await esperar(tester);

    await tester.enterText(
        find.byKey(const Key('campo-nome-abrigo')), 'Escola Nova');
    await tester.enterText(
        find.byKey(const Key('campo-bairro-abrigo')), 'Farolândia');
    await tester.enterText(
        find.byKey(const Key('campo-capacidade-abrigo')), '100');
    await tester.enterText(find.byKey(const Key('campo-vagas-abrigo')), '150');

    final cadastrar = find.widgetWithText(ElevatedButton, 'Cadastrar abrigo');
    await tester.ensureVisible(cadastrar);
    await tester.tap(cadastrar);
    await tester.pump();
    expect(find.text('Mais que a capacidade.'), findsOneWidget);
    expect(find.text('Escolha o local do abrigo.'), findsOneWidget);
    expect(abrigos.salvos, isEmpty);

    await tester.enterText(find.byKey(const Key('campo-vagas-abrigo')), '40');
    final minhaPosicao = find.text('Usar minha posição atual');
    await tester.ensureVisible(minhaPosicao);
    await tester.tap(minhaPosicao);
    await tester.pump();
    await tester.ensureVisible(cadastrar);
    await tester.tap(cadastrar);
    await esperar(tester);

    expect(abrigos.salvos, hasLength(1));
    expect(abrigos.salvos.single.vagasDisponiveis, 40);
    expect(abrigos.salvos.single.localizacao, usuarioProvisorio);
    expect(find.text('Escola Nova'), findsOneWidget);
  });

  testWidgets('Botões − e + mudam as vagas do abrigo', (tester) async {
    abrigos.cadastrados.value = [abrigosDeExemplo.first];
    await abrir(tester, const TelaAbrigosDefesaCivil());

    expect(find.text('42 vagas'), findsOneWidget);
    await tester.tap(find.byTooltip('Uma vaga a mais'));
    await esperar(tester);
    expect(find.text('43 vagas'), findsOneWidget);
  });

  testWidgets('Alerta ativo aparece para todos no Início e na aba Avisos',
      (tester) async {
    alertas.alertas.value = [
      alertaAtivo(),
      Alerta(
        id: 'velho',
        titulo: 'Alerta que já acabou',
        descricao: '',
        nivel: Gravidade.leve,
        origem: OrigemAlerta.comunidade,
        emitidoEm: agora.subtract(const Duration(days: 1)),
        expiraEm: agora.subtract(const Duration(hours: 1)),
      ),
    ];
    await tester.pumpWidget(const EnchenteAlertaApp());

    expect(find.text('Chuva forte nas próximas 3 horas'), findsOneWidget);
    expect(find.text('Alerta que já acabou'), findsNothing);

    // Tocar mostra todos os alertas ativos com a descrição.
    await tester.tap(find.text('Chuva forte nas próximas 3 horas'));
    await esperar(tester);
    expect(find.text('Alertas da Defesa Civil'), findsOneWidget);
    expect(find.text('Evite a Av. Beira Mar'), findsOneWidget);
    Navigator.of(tester.element(find.text('Alertas da Defesa Civil'))).pop();
    await esperar(tester);

    await tester.tap(find.text('Avisos'));
    await tester.pump();
    expect(find.text('Chuva forte nas próximas 3 horas'), findsWidgets);
  });

  testWidgets('Abrigos próximos mostra os abrigos cadastrados pela Defesa Civil',
      (tester) async {
    abrigos.cadastrados.value = [
      Abrigo(
        id: 'x',
        nome: 'Abrigo Cadastrado',
        bairro: 'Centro',
        localizacao:
            const Distance().offset(usuarioProvisorio, 300, 0),
        capacidade: 50,
        vagasDisponiveis: 20,
      ),
    ];
    await tester.pumpWidget(const EnchenteAlertaApp());
    await tester.tap(find.text('Abrigo'));
    await esperar(tester);

    expect(find.text('Abrigo Cadastrado'), findsOneWidget);
    // Com abrigos cadastrados, os de exemplo somem.
    expect(find.text('Esc. Gonçalo Rollemberg Leite'), findsNothing);
  });
}
