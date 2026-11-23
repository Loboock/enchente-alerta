import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../models/models.dart';
import '../../models/perigo.dart';
import '../../services/areas_risco_service.dart';
import '../../services/erro_servico.dart';
import '../../services/perigos_service.dart';
import '../../utils/cores_gravidade.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/botao_gravidade.dart';
import '../../widgets/mapa/editor_pontos_mapa.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../../widgets/widgets_conta.dart';
import 'acoes_comuns.dart';

/// CRUD das áreas de risco da Defesa Civil: aparecem no mapa de todos, as
/// rotas desviam delas e os alertas podem ser ligados a elas.
class TelaAreasRisco extends StatefulWidget {
  const TelaAreasRisco({super.key});

  @override
  State<TelaAreasRisco> createState() => _TelaAreasRiscoState();
}

class _TelaAreasRiscoState extends State<TelaAreasRisco> {
  @override
  void initState() {
    super.initState();
    PerigosService.instance.iniciar();
  }

  Future<void> _abrir([AreaRisco? area]) async {
    final salvo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TelaFormularioArea(area: area)),
    );
    if (salvo == true && mounted) {
      mostrarMensagem(
        context,
        area == null ? 'Área cadastrada.' : 'Área atualizada.',
      );
    }
  }

  Future<void> _excluir(AreaRisco a) async {
    final ok = await confirmarAcao(
      context,
      titulo: 'Excluir área de risco?',
      texto: '"${a.nome}" sai do mapa e as rotas deixam de desviar dela.',
      botao: 'Excluir',
    );
    if (!ok || !mounted) return;
    await executarComAviso(
      context,
      () => AreasRiscoService.instance.excluir(a),
      sucesso: 'Área excluída.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: const AppBarTela(
        voltar: true,
        titulo: 'Áreas de risco',
        subtitulo: 'Desenhadas no mapa',
        ajuda: TextosAjuda.areasRisco,
      ),
      body: ValueListenableBuilder<List<Perigo>>(
        valueListenable: PerigosService.instance.perigos,
        builder: (context, _, _) {
          final areas = PerigosService.instance.areas;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ElevatedButton.icon(
                onPressed: () => _abrir(),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Nova área de risco'),
              ),
              const SizedBox(height: 16),
              if (areas.isEmpty)
                Text(
                  'Nenhuma área de risco cadastrada.',
                  style: TextStyle(color: cores.onSurfaceVariant),
                ),
              for (final a in areas)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      Icons.warning_rounded,
                      color: a.nivelAtual.cor(cores),
                      size: 32,
                    ),
                    title: Text(a.nome),
                    subtitle: Text(
                      'Nível ${a.nivelAtual.rotulo} · ${a.poligono.length} pontos',
                    ),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: 'Editar área',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _abrir(a),
                        ),
                        IconButton(
                          tooltip: 'Excluir área',
                          icon: Icon(Icons.delete_outline, color: cores.error),
                          onPressed: () => _excluir(a),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class TelaFormularioArea extends StatefulWidget {
  const TelaFormularioArea({super.key, this.area});

  final AreaRisco? area;

  @override
  State<TelaFormularioArea> createState() => _TelaFormularioAreaState();
}

class _TelaFormularioAreaState extends State<TelaFormularioArea> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.area?.nome);
  late Gravidade _nivel = widget.area?.nivelAtual ?? Gravidade.moderado;
  late List<LatLng> _pontos = [...?widget.area?.poligono];
  String? _erro;
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final valido = _form.currentState?.validate() ?? false;
    setState(
      () => _erro = _pontos.length < 3
          ? 'Marque pelo menos 3 pontos no mapa.'
          : null,
    );
    if (!valido || _pontos.length < 3) return;
    setState(() => _salvando = true);
    try {
      await AreasRiscoService.instance.salvar(
        AreaRisco(
          id: widget.area?.id ?? '',
          nome: _nome.text.trim(),
          nivelAtual: _nivel,
          poligono: _pontos,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on ServicoException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final editando = widget.area != null;
    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: AppBarTela(
        voltar: true,
        titulo: editando ? 'Editar área' : 'Nova área de risco',
        ajuda: TextosAjuda.areasRisco,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('campo-nome-area'),
              controller: _nome,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex.: Margem do Rio Poxim',
              ),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'Informe o nome da área.'
                  : null,
            ),
            const Text(
              'Nível de risco',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final g in Gravidade.values) ...[
                  if (g != Gravidade.values.first) const SizedBox(width: 10),
                  Expanded(
                    child: BotaoGravidade(
                      gravidade: g,
                      selecionada: _nivel == g,
                      aoTocar: () => setState(() => _nivel = g),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Contorno da área',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            EditorPontosMapa(
              pontos: _pontos,
              fechado: true,
              cor: _nivel.cor(cores),
              aoMudar: (p) => setState(() => _pontos = p),
            ),
            if (_erro != null)
              Text(_erro!, style: TextStyle(color: cores.error)),
            const SizedBox(height: 16),
            PrimaryButton(
              text: editando ? 'Salvar alterações' : 'Cadastrar área',
              onPressed: _salvar,
              loading: _salvando,
            ),
          ],
        ),
      ),
    );
  }
}
