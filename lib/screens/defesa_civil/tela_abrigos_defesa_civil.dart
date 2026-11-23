import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/abrigos_service.dart';
import '../../utils/situacao_abrigo.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/scaffold_com_abas.dart';
import 'acoes_comuns.dart';
import 'tela_formulario_abrigo.dart';

/// CRUD de abrigos da Defesa Civil, com ajuste rápido das vagas.
class TelaAbrigosDefesaCivil extends StatefulWidget {
  const TelaAbrigosDefesaCivil({super.key});

  @override
  State<TelaAbrigosDefesaCivil> createState() => _TelaAbrigosDefesaCivilState();
}

class _TelaAbrigosDefesaCivilState extends State<TelaAbrigosDefesaCivil> {
  final _servico = AbrigosService.instance;
  bool _importando = false;

  @override
  void initState() {
    super.initState();
    _servico.iniciar();
  }

  Future<void> _abrirFormulario([Abrigo? abrigo]) async {
    final salvo = await abrirFormularioAbrigo(context, abrigo: abrigo);
    if (salvo == true && mounted) {
      mostrarMensagem(
        context,
        abrigo == null ? 'Abrigo cadastrado.' : 'Abrigo atualizado.',
      );
    }
  }

  Future<void> _vagas(Abrigo a, int novas) => executarComAviso(
    context,
    () => _servico.alterarVagas(a, novas),
    sucesso: '${a.nome}: ${novas.clamp(0, a.capacidade)} vagas.',
  );

  Future<void> _excluir(Abrigo a) async {
    final ok = await confirmarAcao(
      context,
      titulo: 'Excluir abrigo?',
      texto:
          '"${a.nome}" sai da lista dos moradores. Para tirar só por um '
          'tempo, edite e desative o abrigo.',
      botao: 'Excluir',
    );
    if (!ok || !mounted) return;
    await executarComAviso(
      context,
      () => _servico.excluir(a),
      sucesso: 'Abrigo excluído.',
    );
  }

  Future<void> _cadastrarExemplos() async {
    setState(() => _importando = true);
    await executarComAviso(
      context,
      _servico.cadastrarExemplos,
      sucesso: 'Abrigos de exemplo cadastrados. Agora é só ajustar.',
    );
    if (mounted) setState(() => _importando = false);
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: const AppBarTela(
        voltar: true,
        titulo: 'Abrigos',
        subtitulo: 'Cadastro e vagas',
        ajuda: TextosAjuda.abrigosDefesaCivil,
      ),
      body: ValueListenableBuilder<List<Abrigo>>(
        valueListenable: _servico.cadastrados,
        builder: (context, lista, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton.icon(
              onPressed: _abrirFormulario,
              icon: const Icon(Icons.add_home_outlined),
              label: const Text('Novo abrigo'),
            ),
            const SizedBox(height: 16),
            if (lista.isEmpty) ...[
              Text(
                'Nenhum abrigo cadastrado. Enquanto isso, os moradores veem '
                'os abrigos de exemplo.',
                style: TextStyle(color: cores.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _importando ? null : _cadastrarExemplos,
                child: const Text('Cadastrar os abrigos de exemplo'),
              ),
            ],
            for (final a in lista)
              _CartaoAbrigo(
                abrigo: a,
                aoMenos: a.vagasDisponiveis > 0
                    ? () => _vagas(a, a.vagasDisponiveis - 1)
                    : null,
                aoMais: a.vagasDisponiveis < a.capacidade
                    ? () => _vagas(a, a.vagasDisponiveis + 1)
                    : null,
                aoEditar: () => _abrirFormulario(a),
                aoExcluir: () => _excluir(a),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartaoAbrigo extends StatelessWidget {
  const _CartaoAbrigo({
    required this.abrigo,
    required this.aoMenos,
    required this.aoMais,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final Abrigo abrigo;
  final VoidCallback? aoMenos;
  final VoidCallback? aoMais;
  final VoidCallback aoEditar;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final a = abrigo;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cores.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    a.nome,
                    style: TextStyle(
                      color: cores.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!a.ativo)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: const Text('Desativado'),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: cores.outline),
                    ),
                  ),
              ],
            ),
            Text(
              '${a.bairro} · capacidade ${a.capacidade} · ${a.situacao}',
              style: TextStyle(color: cores.onSurfaceVariant),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Uma vaga a menos',
                  onPressed: aoMenos,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '${a.vagasDisponiveis} vagas',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  tooltip: 'Uma vaga a mais',
                  onPressed: aoMais,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                TextButton(onPressed: aoEditar, child: const Text('Editar')),
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
