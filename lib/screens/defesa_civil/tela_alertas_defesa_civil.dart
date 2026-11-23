import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/alertas_service.dart';
import '../../utils/cores_gravidade.dart';
import '../../utils/formatacao.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/scaffold_com_abas.dart';
import 'acoes_comuns.dart';
import 'tela_formulario_alerta.dart';

/// CRUD de alertas da Defesa Civil: emitir, editar, encerrar e excluir.
class TelaAlertasDefesaCivil extends StatefulWidget {
  const TelaAlertasDefesaCivil({super.key});

  @override
  State<TelaAlertasDefesaCivil> createState() =>
      _TelaAlertasDefesaCivilState();
}

class _TelaAlertasDefesaCivilState extends State<TelaAlertasDefesaCivil> {
  @override
  void initState() {
    super.initState();
    AlertasService.instance.iniciar();
  }

  Future<void> _abrirFormulario([Alerta? alerta]) async {
    final salvo = await abrirFormularioAlerta(context, alerta: alerta);
    if (salvo == true && mounted) {
      mostrarMensagem(
          context, alerta == null ? 'Alerta emitido.' : 'Alerta atualizado.');
    }
  }

  Future<void> _encerrar(Alerta a) async {
    final ok = await confirmarAcao(
      context,
      titulo: 'Encerrar alerta?',
      texto: '"${a.titulo}" deixa de aparecer para os moradores agora.',
      botao: 'Encerrar',
    );
    if (!ok || !mounted) return;
    await executarComAviso(
      context,
      () => AlertasService.instance.encerrar(a),
      sucesso: 'Alerta encerrado.',
    );
  }

  Future<void> _excluir(Alerta a) async {
    final ok = await confirmarAcao(
      context,
      titulo: 'Excluir alerta?',
      texto: '"${a.titulo}" é apagado de vez.',
      botao: 'Excluir',
    );
    if (!ok || !mounted) return;
    await executarComAviso(
      context,
      () => AlertasService.instance.excluir(a),
      sucesso: 'Alerta excluído.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final servico = AlertasService.instance;
    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: const AppBarTela(
        titulo: 'Alertas',
        subtitulo: 'Emitidos pela Defesa Civil',
        ajuda: TextosAjuda.alertasDefesaCivil,
      ),
      body: ValueListenableBuilder<List<Alerta>>(
        valueListenable: servico.alertas,
        builder: (context, todos, _) {
          final agora = DateTime.now();
          final ativos = servico.ativos(agora);
          final encerrados = todos.where((a) => !a.estaAtivo(agora)).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ElevatedButton.icon(
                onPressed: _abrirFormulario,
                icon: const Icon(Icons.add_alert_outlined),
                label: const Text('Emitir alerta'),
              ),
              const SizedBox(height: 20),
              _Titulo('Ativos (${ativos.length})'),
              if (ativos.isEmpty)
                const _Vazio('Nenhum alerta ativo agora.'),
              for (final a in ativos)
                _CartaoAlerta(
                  alerta: a,
                  agora: agora,
                  aoEditar: () => _abrirFormulario(a),
                  aoEncerrar: () => _encerrar(a),
                  aoExcluir: () => _excluir(a),
                ),
              if (encerrados.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Titulo('Encerrados (${encerrados.length})'),
                for (final a in encerrados)
                  _CartaoAlerta(
                    alerta: a,
                    agora: agora,
                    aoEditar: () => _abrirFormulario(a),
                    aoExcluir: () => _excluir(a),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          texto,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _Vazio extends StatelessWidget {
  const _Vazio(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          texto,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
}

/// Texto de quanto falta (ou há quanto tempo acabou).
String _validade(Alerta a, DateTime agora) {
  if (!a.estaAtivo(agora)) {
    return 'Encerrado ${formatarTempoAtras(a.expiraEm, agora: agora)}';
  }
  final falta = a.expiraEm.difference(agora);
  if (falta.inHours >= 1) return 'Termina em ${falta.inHours} h';
  return 'Termina em ${falta.inMinutes.clamp(1, 59)} min';
}

class _CartaoAlerta extends StatelessWidget {
  const _CartaoAlerta({
    required this.alerta,
    required this.agora,
    required this.aoEditar,
    required this.aoExcluir,
    this.aoEncerrar,
  });

  final Alerta alerta;
  final DateTime agora;
  final VoidCallback aoEditar;
  final VoidCallback? aoEncerrar;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final a = alerta;
    final ativo = a.estaAtivo(agora);
    final cor = ativo ? a.nivel.cor(cores) : cores.outline;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${a.nivel.rotulo} · ${a.origem.rotulo}'.toUpperCase(),
              style: TextStyle(
                  color: cor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              a.titulo,
              style: TextStyle(
                color: cores.primary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (a.descricao.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(a.descricao),
            ],
            const SizedBox(height: 4),
            Text(
              'Emitido ${formatarTempoAtras(a.emitidoEm, agora: agora)} · '
              '${_validade(a, agora)}',
              style: TextStyle(color: cores.onSurfaceVariant, fontSize: 13),
            ),
            Wrap(
              children: [
                TextButton(onPressed: aoEditar, child: const Text('Editar')),
                if (aoEncerrar != null)
                  TextButton(
                      onPressed: aoEncerrar, child: const Text('Encerrar')),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: cores.error),
                  onPressed: aoExcluir,
                  child: const Text('Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
