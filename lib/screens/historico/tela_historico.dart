import 'package:flutter/material.dart';

import '../../data/dados_provisorios.dart';
import '../../models/models.dart';
import '../../utils/cores_gravidade.dart';
import '../../utils/formatacao.dart';
import '../../widgets/app_bar_tela.dart';

/// Tela "06 Histórico" do protótipo: lista dos últimos alagamentos
/// registrados na região do usuário, do mais recente para o mais antigo.
class TelaHistorico extends StatelessWidget {
  const TelaHistorico({super.key, this.itens});

  /// Ocorrências a exibir. Se não vier nada, usa os dados provisórios.
  final List<Ocorrencia>? itens;

  @override
  Widget build(BuildContext context) {
    final lista = [...(itens ?? historicoProvisorio)]
      ..sort((a, b) => b.criadaEm.compareTo(a.criadaEm));

    return Scaffold(
      appBar: const AppBarTela(
        titulo: 'Histórico',
        subtitulo: 'Últimos alagamentos na sua região',
      ),
      body: lista.isEmpty
          ? const _HistoricoVazio()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, i) =>
                  _CartaoHistorico(ocorrencia: lista[i]),
            ),
    );
  }
}

class _CartaoHistorico extends StatelessWidget {
  const _CartaoHistorico({required this.ocorrencia});

  final Ocorrencia ocorrencia;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final data = formatarDataCurta(ocorrencia.criadaEm);
    final gravidade = ocorrencia.gravidade;

    // A cor do ponto não é a única pista: a gravidade também aparece em
    // texto, e o leitor de tela lê a frase completa (RNF02, RNF10).
    return Semantics(
      container: true,
      label: '${ocorrencia.endereco}. Gravidade ${gravidade.rotulo}, '
          '${ocorrencia.nivelAguaCm} centímetros de água, em $data',
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
                        '${gravidade.rotulo} · ${ocorrencia.nivelAguaCm} cm · $data',
                        style: TextStyle(
                          fontSize: 13,
                          color: cores.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoricoVazio extends StatelessWidget {
  const _HistoricoVazio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Nenhum alagamento registrado na sua região.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
