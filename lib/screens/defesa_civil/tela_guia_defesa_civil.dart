import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/erro_servico.dart';
import '../../services/guias_service.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../../widgets/widgets_conta.dart';
import 'acoes_comuns.dart';

/// CRUD das orientações do Guia de segurança (coleção `guias`).
class TelaGuiaDefesaCivil extends StatefulWidget {
  const TelaGuiaDefesaCivil({super.key});

  @override
  State<TelaGuiaDefesaCivil> createState() => _TelaGuiaDefesaCivilState();
}

class _TelaGuiaDefesaCivilState extends State<TelaGuiaDefesaCivil> {
  final _servico = GuiasService.instance;
  bool _publicando = false;

  @override
  void initState() {
    super.initState();
    _servico.iniciar();
  }

  Future<void> _abrir([GuiaOrientacao? g]) async {
    final salvo = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => TelaFormularioGuia(guia: g)));
    if (salvo == true && mounted) {
      mostrarMensagem(context,
          g == null ? 'Orientação publicada.' : 'Orientação atualizada.');
    }
  }

  Future<void> _excluir(GuiaOrientacao g) async {
    final ok = await confirmarAcao(context,
        titulo: 'Excluir orientação?',
        texto: '"${g.conteudo}" sai do Guia dos moradores.',
        botao: 'Excluir');
    if (!ok || !mounted) return;
    await executarComAviso(context, () => _servico.excluir(g),
        sucesso: 'Orientação excluída.');
  }

  Future<void> _publicarExemplos() async {
    setState(() => _publicando = true);
    await executarComAviso(context, _servico.publicarExemplos,
        sucesso: 'Guia de exemplo publicado. Agora é só ajustar.');
    if (mounted) setState(() => _publicando = false);
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: const AppBarTela(
        titulo: 'Guia de segurança',
        subtitulo: 'Orientações para os moradores',
        ajuda: TextosAjuda.guiaDefesaCivil,
      ),
      body: ValueListenableBuilder<List<GuiaOrientacao>>(
        valueListenable: _servico.publicadas,
        builder: (context, lista, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton.icon(
              onPressed: () => _abrir(),
              icon: const Icon(Icons.add),
              label: const Text('Nova orientação'),
            ),
            const SizedBox(height: 16),
            if (lista.isEmpty) ...[
              Text(
                  'Nenhuma orientação publicada. Enquanto isso, os moradores '
                  'veem o guia de exemplo.',
                  style: TextStyle(color: cores.onSurfaceVariant)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _publicando ? null : _publicarExemplos,
                child: const Text('Publicar o guia de exemplo'),
              ),
            ],
            for (final fase in FaseGuia.values)
              if (lista.any((g) => g.fase == fase)) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(fase.rotulo.toUpperCase(),
                      style: TextStyle(
                          color: cores.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                ),
                for (final g in GuiaOrientacao.filtrarPorFase(lista, fase))
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(g.conteudo),
                      subtitle: Text('${g.titulo} · ordem ${g.ordem}'),
                      onTap: () => _abrir(g),
                      trailing: IconButton(
                        tooltip: 'Excluir orientação',
                        icon: Icon(Icons.delete_outline, color: cores.error),
                        onPressed: () => _excluir(g),
                      ),
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

class TelaFormularioGuia extends StatefulWidget {
  const TelaFormularioGuia({super.key, this.guia});

  final GuiaOrientacao? guia;

  @override
  State<TelaFormularioGuia> createState() => _TelaFormularioGuiaState();
}

class _TelaFormularioGuiaState extends State<TelaFormularioGuia> {
  final _form = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.guia?.titulo);
  late final _conteudo = TextEditingController(text: widget.guia?.conteudo);
  late final _ordem =
      TextEditingController(text: '${widget.guia?.ordem ?? 1}');
  late FaseGuia _fase = widget.guia?.fase ?? FaseGuia.antes;
  bool _salvando = false;

  @override
  void dispose() {
    for (final c in [_titulo, _conteudo, _ordem]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _salvando = true);
    try {
      await GuiasService.instance.salvar(GuiaOrientacao(
        id: widget.guia?.id ?? '',
        titulo: _titulo.text.trim(),
        conteudo: _conteudo.text.trim(),
        fase: _fase,
        ordem: int.tryParse(_ordem.text) ?? 1,
      ));
      if (mounted) Navigator.pop(context, true);
    } on ServicoException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.guia != null;
    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: AppBarTela(
        titulo: editando ? 'Editar orientação' : 'Nova orientação',
        ajuda: TextosAjuda.guiaDefesaCivil,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<FaseGuia>(
              initialValue: _fase,
              decoration: const InputDecoration(labelText: 'Seção do guia'),
              items: [
                for (final f in FaseGuia.values)
                  DropdownMenuItem(value: f, child: Text(f.rotulo)),
              ],
              onChanged: (f) => setState(() => _fase = f ?? _fase),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('campo-conteudo-guia'),
              controller: _conteudo,
              maxLength: 300,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Orientação',
                  hintText: 'Ex.: Desligue a energia antes de sair de casa'),
              validator: (v) => (v?.trim().length ?? 0) < 5
                  ? 'Escreva a orientação (pelo menos 5 letras).'
                  : null,
            ),
            TextFormField(
              key: const Key('campo-titulo-guia'),
              controller: _titulo,
              maxLength: 120,
              decoration: const InputDecoration(
                  labelText: 'Tema curto', hintText: 'Ex.: Energia'),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Informe o tema.' : null,
            ),
            TextFormField(
              controller: _ordem,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Ordem na seção', hintText: '1 aparece primeiro'),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: editando ? 'Salvar alterações' : 'Publicar orientação',
              onPressed: _salvar,
              loading: _salvando,
            ),
          ],
        ),
      ),
    );
  }
}
