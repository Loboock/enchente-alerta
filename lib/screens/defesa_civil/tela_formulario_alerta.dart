import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/alertas_service.dart';
import '../../services/erro_servico.dart';
import '../../services/perigos_service.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/botao_gravidade.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../../widgets/widgets_conta.dart';

/// Abre o formulário para emitir (sem [alerta]) ou editar um alerta.
/// Devolve true quando salvou.
Future<bool?> abrirFormularioAlerta(BuildContext context, {Alerta? alerta}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => TelaFormularioAlerta(alerta: alerta)),
  );
}

/// Validades oferecidas, contadas a partir do momento em que salva.
const validadesAlerta = <Duration>[
  Duration(hours: 1),
  Duration(hours: 3),
  Duration(hours: 6),
  Duration(hours: 12),
  Duration(hours: 24),
  Duration(hours: 48),
  Duration(hours: 72),
];

class TelaFormularioAlerta extends StatefulWidget {
  const TelaFormularioAlerta({super.key, this.alerta});

  final Alerta? alerta;

  @override
  State<TelaFormularioAlerta> createState() => _TelaFormularioAlertaState();
}

class _TelaFormularioAlertaState extends State<TelaFormularioAlerta> {
  final _form = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.alerta?.titulo);
  late final _descricao =
      TextEditingController(text: widget.alerta?.descricao);
  late Gravidade _nivel = widget.alerta?.nivel ?? Gravidade.moderado;
  late OrigemAlerta _origem =
      widget.alerta?.origem ?? OrigemAlerta.meteorologica;
  Duration _validade = const Duration(hours: 6);

  /// Áreas de risco onde o alerta vale. Vazio = cidade toda.
  late final Set<String> _areas = {...?widget.alerta?.areasRiscoIds};
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.alerta != null;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _erro = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _salvando = true);
    final agora = DateTime.now();
    final antigo = widget.alerta;
    final alerta = Alerta(
      id: antigo?.id ?? '',
      titulo: _titulo.text.trim(),
      descricao: _descricao.text.trim(),
      nivel: _nivel,
      origem: _origem,
      areasRiscoIds: _areas.toList(),
      ocorrenciasIds: antigo?.ocorrenciasIds ?? const [],
      guiasIds: antigo?.guiasIds ?? const [],
      // Editar mantém a data de emissão; a validade recomeça agora.
      emitidoEm: antigo?.emitidoEm ?? agora,
      expiraEm: agora.add(_validade),
    );
    try {
      await AlertasService.instance.salvar(alerta);
      if (mounted) Navigator.of(context).pop(true);
    } on ServicoException catch (e) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erro = e.mensagem;
        });
      }
    }
  }

  String _rotuloValidade(Duration d) =>
      d.inHours == 1 ? '1 hora' : '${d.inHours} horas';

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final rotulo = TextStyle(
      color: cores.primary,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );

    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: AppBarTela(
        titulo: _editando ? 'Editar alerta' : 'Emitir alerta',
        ajuda: TextosAjuda.formularioAlerta,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Título', style: rotulo),
              const SizedBox(height: 6),
              TextFormField(
                key: const Key('campo-titulo-alerta'),
                controller: _titulo,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex.: Chuva forte nas próximas 3 horas',
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Informe o título do alerta.';
                  if (t.length < 5) return 'Use pelo menos 5 caracteres.';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text('Descrição (opcional)', style: rotulo),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descricao,
                maxLength: 1000,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex.: Evite a Av. Beira Mar e procure locais altos',
                ),
              ),
              const SizedBox(height: 8),
              Text('Nível', style: rotulo),
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
              const SizedBox(height: 20),
              Text('Origem', style: rotulo),
              const SizedBox(height: 8),
              SegmentedButton<OrigemAlerta>(
                segments: [
                  for (final o in OrigemAlerta.values)
                    ButtonSegment(value: o, label: Text(o.rotulo)),
                ],
                selected: {_origem},
                onSelectionChanged: (s) => setState(() => _origem = s.first),
              ),
              const SizedBox(height: 20),
              Text('Onde vale', style: rotulo),
              const SizedBox(height: 6),
              _EscolhaAreas(
                selecionadas: _areas,
                aoMudar: (id, marcada) => setState(() =>
                    marcada ? _areas.add(id) : _areas.remove(id)),
              ),
              const SizedBox(height: 20),
              Text(_editando ? 'Válido por mais' : 'Válido por', style: rotulo),
              const SizedBox(height: 6),
              DropdownButtonFormField<Duration>(
                initialValue: _validade,
                items: [
                  for (final d in validadesAlerta)
                    DropdownMenuItem(
                        value: d, child: Text(_rotuloValidade(d))),
                ],
                onChanged: (d) {
                  if (d != null) setState(() => _validade = d);
                },
              ),
              const SizedBox(height: 20),
              if (_erro case final erro?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(erro, style: TextStyle(color: cores.error)),
                ),
              PrimaryButton(
                text: _editando ? 'Salvar alterações' : 'Emitir alerta',
                onPressed: _salvar,
                loading: _salvando,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Áreas de risco cadastradas, para ligar ao alerta. Sem nenhuma marcada,
/// o alerta vale para a cidade toda.
class _EscolhaAreas extends StatelessWidget {
  const _EscolhaAreas({required this.selecionadas, required this.aoMudar});

  final Set<String> selecionadas;
  final void Function(String id, bool marcada) aoMudar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final areas = PerigosService.instance.areas;
    final dica = TextStyle(fontSize: 13, color: cores.onSurfaceVariant);
    if (areas.isEmpty) {
      return Text(
          'Toda a cidade. Cadastre áreas de risco no Painel para avisar só '
          'quem mora perto delas.',
          style: dica);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selecionadas.isEmpty
              ? 'Toda a cidade (nenhuma área marcada).'
              : 'Só para quem está perto das áreas marcadas.',
          style: dica,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final a in areas)
              FilterChip(
                label: Text(a.nome),
                selected: selecionadas.contains(a.id),
                onSelected: (v) => aoMudar(a.id, v),
              ),
          ],
        ),
      ],
    );
  }
}
