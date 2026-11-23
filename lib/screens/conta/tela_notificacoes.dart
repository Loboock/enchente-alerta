import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/alertas_service.dart';
import '../../services/notificacoes_service.dart';
import '../../utils/formatacao.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../../widgets/widgets_conta.dart';
import '../defesa_civil/acoes_comuns.dart';

/// Notificações recebidas: os alertas da Defesa Civil que chegaram para a
/// região da pessoa. Tocar abre o alerta e marca como lida.
class TelaNotificacoes extends StatefulWidget {
  const TelaNotificacoes({super.key});

  @override
  State<TelaNotificacoes> createState() => _TelaNotificacoesState();
}

class _TelaNotificacoesState extends State<TelaNotificacoes> {
  final _servico = NotificacoesService.instance;

  Future<void> _abrir(Notificacao n) async {
    _servico.marcarLida(n).catchError((Object _) {});
    Alerta? alerta;
    for (final a in AlertasService.instance.alertas.value) {
      if (a.id == n.alertaId) alerta = a;
    }
    final ativo = alerta?.estaAtivo() ?? false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(alerta?.titulo ?? 'Alerta da Defesa Civil'),
        content: Text([
          if (alerta == null) n.mensagem,
          if (alerta != null && alerta.descricao.isNotEmpty) alerta.descricao,
          if (alerta != null) 'Nível: ${alerta.nivel.rotulo}',
          ativo ? 'Alerta ativo agora.' : 'Este alerta já foi encerrado.',
        ].join('\n\n')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future<void> _excluir(Notificacao n) => executarComAviso(
      context, () => _servico.excluir(n),
      sucesso: 'Notificação excluída.');

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: barraConta(context, 'Notificações',
          ajuda: TextosAjuda.notificacoes),
      body: ValueListenableBuilder<List<Notificacao>>(
        valueListenable: _servico.notificacoes,
        builder: (context, lista, _) {
          if (lista.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Nenhuma notificação. Os alertas da Defesa Civil para a '
                  'sua região aparecem aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: cores.onSurfaceVariant),
                ),
              ),
            );
          }
          final naoLidas = lista.where((n) => !n.lida).length;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        naoLidas == 0
                            ? 'Todas lidas'
                            : naoLidas == 1
                                ? '1 não lida'
                                : '$naoLidas não lidas',
                        style: TextStyle(color: cores.onSurfaceVariant),
                      ),
                    ),
                    if (naoLidas > 0)
                      TextButton(
                        onPressed: () => executarComAviso(
                            context, _servico.marcarTodasLidas,
                            sucesso: 'Todas marcadas como lidas.'),
                        child: const Text('Marcar todas como lidas'),
                      ),
                  ],
                ),
              ),
              for (final n in lista)
                ListTile(
                  leading: Icon(
                    n.lida
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: n.lida ? cores.onSurfaceVariant : cores.secondary,
                  ),
                  title: Text(
                    n.mensagem,
                    style: TextStyle(
                        fontWeight:
                            n.lida ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Text(
                      '${formatarDataCurta(n.enviadaEm)} · ${formatarTempoAtras(n.enviadaEm)}'),
                  trailing: IconButton(
                    tooltip: 'Excluir notificação',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _excluir(n),
                  ),
                  onTap: () => _abrir(n),
                ),
            ],
          );
        },
      ),
    );
  }
}
