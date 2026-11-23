import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/historico_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/cores_gravidade.dart';
import '../../utils/formatacao.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';

/// Tela "06 Histórico" do protótipo: os alagamentos e vias obstruídas
/// registrados no Firestore, do mais recente para o mais antigo, com a
/// situação de cada um (ativo, resolvido ou expirado).
class TelaHistorico extends StatefulWidget {
  const TelaHistorico({super.key});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  final _servico = HistoricoService.instance;

  @override
  void initState() {
    super.initState();
    _servico.iniciar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarTela(
        titulo: 'Histórico',
        subtitulo: 'Últimos alagamentos na sua região',
        ajuda: TextosAjuda.historico,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(
            [_servico.ocorrencias, _servico.erro, _servico.doCache]),
        builder: (context, _) {
          final lista = _servico.ocorrencias.value;
          final erro = _servico.erro.value;

          if (lista == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (lista.isEmpty) {
            return erro != null
                ? _Mensagem(texto: erro, aoTentarDeNovo: _servico.recarregar)
                : const _Mensagem(
                    texto: 'Nenhum alagamento registrado na sua região.');
          }

          final agora = DateTime.now();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              if (i == 0) {
                return _Resumo(
                  quantidade: lista.length,
                  doCache: _servico.doCache.value,
                );
              }
              final o = lista[i - 1];
              return _CartaoHistorico(
                ocorrencia: o,
                situacao: situacaoNoHistorico(o, agora),
              );
            },
          );
        },
      ),
    );
  }
}

/// Linha acima da lista: quantidade e aviso de dados salvos no aparelho.
class _Resumo extends StatelessWidget {
  const _Resumo({required this.quantidade, required this.doCache});

  final int quantidade;
  final bool doCache;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final estilo = TextStyle(fontSize: 13, color: cores.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          quantidade == 1 ? '1 registro' : '$quantidade registros',
          style: estilo,
        ),
        if (doCache) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.cloud_off, size: 16, color: cores.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sem internet: mostrando o histórico salvo no aparelho.',
                  style: estilo,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CartaoHistorico extends StatelessWidget {
  const _CartaoHistorico({required this.ocorrencia, required this.situacao});

  final Ocorrencia ocorrencia;
  final StatusOcorrencia situacao;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final data = formatarDataCurta(ocorrencia.criadaEm);
    final gravidade = ocorrencia.gravidade;
    final via = ocorrencia.tipo == TipoOcorrencia.viaObstruida;
    final detalhe = via
        ? 'Via obstruída · ${gravidade.rotulo} · $data'
        : '${gravidade.rotulo} · ${ocorrencia.nivelAguaCm} cm · $data';
    final rotuloSituacao = _rotulo(situacao);

    // A cor do ponto não é a única pista: a gravidade também aparece em
    // texto, e o leitor de tela lê a frase completa (RNF02, RNF10).
    return Semantics(
      container: true,
      label: '${ocorrencia.endereco}. ${via ? 'Via obstruída, ' : ''}'
          'gravidade ${gravidade.rotulo}'
          '${via ? '' : ', ${ocorrencia.nivelAguaCm} centímetros de água'}'
          ', em $data. $rotuloSituacao',
      child: ExcludeSemantics(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: gravidade.cor(cores),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ocorrencia.endereco,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cores.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detalhe,
                        style: TextStyle(
                          fontSize: 13,
                          color: cores.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _Selo(texto: rotuloSituacao, cor: _cor(situacao, cores)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _rotulo(StatusOcorrencia s) => switch (s) {
        StatusOcorrencia.ativa => 'Ativo agora',
        StatusOcorrencia.resolvida => 'Resolvido',
        StatusOcorrencia.expirada => 'Expirado',
      };

  static Color _cor(StatusOcorrencia s, ColorScheme cores) => switch (s) {
        StatusOcorrencia.ativa => AppColors.alerta,
        StatusOcorrencia.resolvida => AppColors.seguro,
        StatusOcorrencia.expirada => cores.onSurfaceVariant,
      };
}

/// Selo pequeno com a situação do aviso.
class _Selo extends StatelessWidget {
  const _Selo({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: cor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: cor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.texto, this.aoTentarDeNovo});

  final String texto;
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (aoTentarDeNovo != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: aoTentarDeNovo,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
