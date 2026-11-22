import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../models/perigo.dart';
import '../../services/auth_service.dart';
import '../../services/defesa_civil_service.dart';
import '../../services/erro_servico.dart';
import '../../services/perigos_service.dart';
import '../../utils/cores_gravidade.dart';
import '../../utils/exigir_login.dart';
import '../../utils/formatacao.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/faixa_alertas.dart';
import '../defesa_civil/acoes_comuns.dart';
import 'tela_criar_aviso.dart';
import 'tela_reportar_aviso.dart';

/// Tela "04 Avisos de alagamento" do protótipo (aba Avisos): avisos ativos
/// da comunidade, do mais recente ao mais antigo, em tempo real.
///
/// Qualquer pessoa vê a lista (inclusive o Visitante). Criar, reportar e
/// excluir pedem conta; "Excluir" só aparece nos avisos da própria pessoa
/// (ou em todos, para a Defesa Civil).
class TelaAvisos extends StatefulWidget {
  const TelaAvisos({super.key});

  @override
  State<TelaAvisos> createState() => _TelaAvisosState();
}

class _TelaAvisosState extends State<TelaAvisos> {
  final _auth = AuthService.instance;

  StreamSubscription<Set<String>>? _assinaturaAutor;
  String? _uidOuvido;

  /// Ids dos avisos criados por quem está logado.
  Set<String> _meus = const {};

  @override
  void initState() {
    super.initState();
    PerigosService.instance.iniciar();
    _auth.addListener(_aoMudarConta);
    _aoMudarConta();
  }

  @override
  void dispose() {
    _auth.removeListener(_aoMudarConta);
    _assinaturaAutor?.cancel();
    super.dispose();
  }

  /// Entrou, saiu ou trocou de conta: volta a buscar os avisos da pessoa.
  void _aoMudarConta() {
    final uid = _auth.user?.uid;
    if (uid == _uidOuvido) {
      // O perfil (Defesa Civil) pode ter chegado depois do login.
      if (mounted) setState(() {});
      return;
    }
    _uidOuvido = uid;
    _assinaturaAutor?.cancel();
    _assinaturaAutor = null;
    if (mounted) setState(() => _meus = const {});
    if (uid == null) return;
    _assinaturaAutor = PerigosService.instance.idsDoAutor(uid).listen(
      (ids) {
        if (mounted) setState(() => _meus = ids);
      },
    );
  }

  bool get _ehDefesaCivil => _auth.usuario?.ehDefesaCivil ?? false;

  bool _podeExcluir(Ocorrencia o) => _meus.contains(o.id) || _ehDefesaCivil;

  /// Defesa Civil: a água baixou, o aviso sai do mapa e vai para o histórico.
  Future<void> _resolver(Ocorrencia o) async {
    final ok = await confirmarAcao(
      context,
      titulo: 'Resolver aviso?',
      texto: 'O aviso em ${o.endereco} sai do mapa e das rotas e fica no '
          'histórico.',
      botao: 'Resolver',
    );
    if (!ok || !mounted) return;
    try {
      await DefesaCivilService.instance.resolverAviso(o.id);
      _mostrar('Aviso resolvido. Ele saiu do mapa.');
    } on ServicoException catch (e) {
      _mostrar(e.mensagem);
    }
  }

  Future<void> _criar() async {
    if (!exigirLogin(context, acao: 'criar avisos')) return;
    final criado = await abrirCriarAviso(context);
    if (criado == true && mounted) {
      _mostrar('Aviso criado! Ele já aparece no mapa e nesta lista.');
    }
  }

  Future<void> _reportar(Ocorrencia o) async {
    if (!exigirLogin(context, acao: 'reportar avisos')) return;
    final enviado = await abrirReportarAviso(context, o);
    if (enviado == true && mounted) {
      _mostrar('Denúncia enviada. A Defesa Civil vai analisar este aviso.');
    }
  }

  Future<void> _excluir(Ocorrencia o) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Excluir aviso?'),
        content: Text('O aviso em ${o.endereco} sai do mapa e da lista '
            'para todos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    try {
      await PerigosService.instance.excluir(o);
      _mostrar('Aviso excluído.');
    } on PerigoException catch (e) {
      _mostrar(e.mensagem);
    }
  }

  void _mostrar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarTela(
        titulo: 'Avisos de alagamento',
        subtitulo: 'Atualizado agora',
        ajuda: TextosAjuda.avisos,
      ),
      body: ValueListenableBuilder<List<Perigo>>(
        valueListenable: PerigosService.instance.perigos,
        builder: (context, perigos, _) {
          // Só os avisos da comunidade; as áreas da Defesa Civil ficam no mapa.
          final avisos = <Ocorrencia>[
            for (final p in perigos) ?p.ocorrencia,
          ]..sort((a, b) => b.criadaEm.compareTo(a.criadaEm));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const FaixaAlertas(margem: EdgeInsets.only(bottom: 14)),
              if (avisos.isEmpty) const _ListaVazia(),
              for (final o in avisos) ...[
                _CartaoAviso(
                  ocorrencia: o,
                  aoReportar: () => _reportar(o),
                  aoExcluir: _podeExcluir(o) ? () => _excluir(o) : null,
                  aoResolver: _ehDefesaCivil ? () => _resolver(o) : null,
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _criar,
                icon: const Icon(Icons.add),
                label: const Text('Criar aviso'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartaoAviso extends StatelessWidget {
  const _CartaoAviso({
    required this.ocorrencia,
    required this.aoReportar,
    this.aoExcluir,
    this.aoResolver,
  });

  final Ocorrencia ocorrencia;
  final VoidCallback aoReportar;

  /// Null quando a pessoa não pode excluir este aviso.
  final VoidCallback? aoExcluir;

  /// Só para a Defesa Civil.
  final VoidCallback? aoResolver;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final o = ocorrencia;
    final cor = o.gravidade.cor(cores);
    final quando = formatarTempoAtras(o.criadaEm);
    final etiqueta = '${o.tipo.rotulo} ${o.gravidade.rotulo}'.toUpperCase();
    final detalhe = o.nivelAguaCm > 0
        ? 'Água a ${o.nivelAguaCm} cm · $quando'
        : quando[0].toUpperCase() + quando.substring(1);

    return Container(
      decoration: BoxDecoration(
        color: cores.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cores.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Faixa colorida da gravidade, como no protótipo.
            Container(width: 5, color: cor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'Gravidade ${o.gravidade.rotulo}',
                      excludeSemantics: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          etiqueta,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      o.endereco,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cores.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detalhe,
                      style: TextStyle(color: cores.onSurfaceVariant),
                    ),
                    if (o.descricao case final descricao?) ...[
                      const SizedBox(height: 4),
                      Text('"$descricao"'),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (aoResolver != null)
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(110, 44),
                            ),
                            onPressed: aoResolver,
                            child: const Text('Resolver'),
                          ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 44),
                          ),
                          onPressed: aoReportar,
                          child: const Text('Reportar'),
                        ),
                        if (aoExcluir != null)
                          TextButton(
                            onPressed: aoExcluir,
                            child: const Text('Excluir'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia();

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
      child: Column(
        children: [
          Icon(Icons.water_drop_outlined, size: 56, color: cores.primary),
          const SizedBox(height: 12),
          Text(
            'Nenhum aviso de alagamento ativo agora.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: cores.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Viu água subindo? Crie um aviso para a vizinhança.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cores.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
