import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../models/perigo.dart';
import '../../services/defesa_civil_service.dart';
import '../../services/perigos_service.dart';
import '../../utils/cores_gravidade.dart';
import '../../utils/formatacao.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/scaffold_com_abas.dart';
import 'acoes_comuns.dart';

/// Denúncias dos moradores ("Reportar aviso" e "Água baixou"), agrupadas
/// por aviso. A Defesa Civil resolve, mantém ou exclui cada aviso.
class TelaDenuncias extends StatefulWidget {
  const TelaDenuncias({super.key});

  @override
  State<TelaDenuncias> createState() => _TelaDenunciasState();
}

class _TelaDenunciasState extends State<TelaDenuncias> {
  @override
  void initState() {
    super.initState();
    DefesaCivilService.instance.iniciar();
    PerigosService.instance.iniciar();
  }

  Future<void> _resolver(GrupoDenuncias g, Ocorrencia o) async {
    final ok = await confirmarAcao(
      context,
      titulo: 'Resolver aviso?',
      texto: 'O aviso em ${o.endereco} sai do mapa e das rotas e fica no '
          'histórico. As denúncias dele são arquivadas.',
      botao: 'Resolver',
    );
    if (!ok || !mounted) return;
    await executarComAviso(
      context,
      () => DefesaCivilService.instance
          .resolverAviso(g.ocorrenciaId, denuncias: g.denuncias),
      sucesso: 'Aviso resolvido.',
    );
  }

  Future<void> _manter(GrupoDenuncias g) async {
    final ok = await confirmarAcao(
      context,
      titulo: 'Manter aviso?',
      texto: 'As denúncias são apagadas e o aviso continua no mapa.',
      botao: 'Manter',
    );
    if (!ok || !mounted) return;
    await executarComAviso(
      context,
      () => DefesaCivilService.instance
          .manterAviso(g.ocorrenciaId, g.denuncias),
      sucesso: 'Denúncias arquivadas. O aviso continua ativo.',
    );
  }

  Future<void> _excluir(GrupoDenuncias g) async {
    final ok = await confirmarAcao(
      context,
      titulo: 'Excluir aviso?',
      texto: 'Use para aviso falso ou abusivo. O aviso e as denúncias são '
          'apagados para todos.',
      botao: 'Excluir',
    );
    if (!ok || !mounted) return;
    await executarComAviso(
      context,
      () => DefesaCivilService.instance
          .excluirAviso(g.ocorrenciaId, g.denuncias),
      sucesso: 'Aviso excluído.',
    );
  }

  Future<void> _arquivar(GrupoDenuncias g) => executarComAviso(
        context,
        () => DefesaCivilService.instance
            .manterAviso(g.ocorrenciaId, g.denuncias),
        sucesso: 'Denúncias arquivadas.',
      );

  @override
  Widget build(BuildContext context) {
    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: const AppBarTela(
        titulo: 'Denúncias',
        subtitulo: 'Avisos marcados como errados',
        ajuda: TextosAjuda.denuncias,
      ),
      body: ValueListenableBuilder<List<Perigo>>(
        valueListenable: PerigosService.instance.perigos,
        builder: (context, perigos, _) {
          final ativos = {
            for (final o in [for (final p in perigos) ?p.ocorrencia]) o.id: o,
          };
          return ValueListenableBuilder<List<GrupoDenuncias>>(
            valueListenable: DefesaCivilService.instance.pendentes,
            builder: (context, grupos, _) {
              if (grupos.isEmpty) return const _SemDenuncias();
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: grupos.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final g = grupos[i];
                  final o = ativos[g.ocorrenciaId];
                  return _CartaoDenuncia(
                    grupo: g,
                    ocorrencia: o,
                    aoResolver: o == null ? null : () => _resolver(g, o),
                    aoManter: o == null ? null : () => _manter(g),
                    aoExcluir: o == null ? null : () => _excluir(g),
                    aoArquivar: () => _arquivar(g),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CartaoDenuncia extends StatelessWidget {
  const _CartaoDenuncia({
    required this.grupo,
    required this.ocorrencia,
    required this.aoResolver,
    required this.aoManter,
    required this.aoExcluir,
    required this.aoArquivar,
  });

  final GrupoDenuncias grupo;

  /// Null quando o aviso já expirou, foi resolvido ou excluído.
  final Ocorrencia? ocorrencia;
  final VoidCallback? aoResolver;
  final VoidCallback? aoManter;
  final VoidCallback? aoExcluir;
  final VoidCallback aoArquivar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final o = ocorrencia;
    final cor = o?.gravidade.cor(cores) ?? cores.outline;
    final total = grupo.denuncias.length;

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
            Container(width: 5, color: cor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      total == 1 ? '1 DENÚNCIA' : '$total DENÚNCIAS',
                      style: TextStyle(
                        color: cores.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      o?.endereco ?? 'Aviso já encerrado ou excluído',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cores.primary,
                      ),
                    ),
                    if (o != null)
                      Text(
                        '${o.tipo.rotulo} ${o.gravidade.rotulo.toLowerCase()}'
                        ' · ${o.confirmacoes} confirmação(ões) · '
                        'criado ${formatarTempoAtras(o.criadaEm)}',
                        style: TextStyle(color: cores.onSurfaceVariant),
                      ),
                    const SizedBox(height: 10),
                    for (final d in grupo.denuncias)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.flag_outlined,
                                size: 18, color: cores.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${d.motivo.rotulo} · '
                                '${formatarTempoAtras(d.criadaEm)}'
                                '${d.detalhes == null ? '' : '\n"${d.detalhes}"'}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (o == null)
                      OutlinedButton(
                        onPressed: aoArquivar,
                        child: const Text('Arquivar denúncias'),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          FilledButton(
                            onPressed: aoResolver,
                            child: const Text('Resolver'),
                          ),
                          OutlinedButton(
                            onPressed: aoManter,
                            child: const Text('Manter'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: cores.error),
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

class _SemDenuncias extends StatelessWidget {
  const _SemDenuncias();

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_outlined, size: 56, color: cores.primary),
            const SizedBox(height: 12),
            Text(
              'Nenhuma denúncia pendente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: cores.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
