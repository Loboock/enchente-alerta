import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../models/models.dart';
import '../../services/abrigos_service.dart';
import '../../services/erro_servico.dart';
import '../../services/rotas_fuga_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatacao.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/botao_gravidade.dart';
import '../../widgets/mapa/editor_pontos_mapa.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../../widgets/widgets_conta.dart';
import 'acoes_comuns.dart';

/// CRUD das rotas de fuga oficiais: caminhos traçados pela Defesa Civil
/// até um abrigo, que aparecem em verde no mapa de todos.
class TelaRotasFugaDefesaCivil extends StatefulWidget {
  const TelaRotasFugaDefesaCivil({super.key});

  @override
  State<TelaRotasFugaDefesaCivil> createState() =>
      _TelaRotasFugaDefesaCivilState();
}

class _TelaRotasFugaDefesaCivilState extends State<TelaRotasFugaDefesaCivil> {
  final _servico = RotasFugaService.instance;

  @override
  void initState() {
    super.initState();
    _servico.iniciar();
    AbrigosService.instance.iniciar();
  }

  Future<void> _abrir([RotaFuga? rota]) async {
    final salvo = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => TelaFormularioRota(rota: rota)));
    if (salvo == true && mounted) {
      mostrarMensagem(
          context, rota == null ? 'Rota cadastrada.' : 'Rota atualizada.');
    }
  }

  Future<void> _excluir(RotaFuga r, String abrigo) async {
    final ok = await confirmarAcao(context,
        titulo: 'Excluir rota de fuga?',
        texto: 'A rota até "$abrigo" sai do mapa dos moradores.',
        botao: 'Excluir');
    if (!ok || !mounted) return;
    await executarComAviso(context, () => _servico.excluir(r),
        sucesso: 'Rota excluída.');
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: const AppBarTela(
        titulo: 'Rotas de fuga',
        subtitulo: 'Caminhos oficiais até os abrigos',
        ajuda: TextosAjuda.rotasFugaDefesaCivil,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(
            [_servico.rotas, AbrigosService.instance.cadastrados]),
        builder: (context, _) {
          final nomes = {
            for (final a in AbrigosService.instance.cadastrados.value)
              a.id: a.nome,
          };
          final rotas = _servico.rotas.value;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ElevatedButton.icon(
                onPressed: () => _abrir(),
                icon: const Icon(Icons.alt_route),
                label: const Text('Nova rota de fuga'),
              ),
              const SizedBox(height: 16),
              if (rotas.isEmpty)
                Text(
                    'Nenhuma rota cadastrada. Os moradores continuam com as '
                    'rotas calculadas na hora, que desviam dos alagamentos.',
                    style: TextStyle(color: cores.onSurfaceVariant)),
              for (final r in rotas)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Até ${nomes[r.abrigoId] ?? 'abrigo excluído'}',
                          style: TextStyle(
                              color: cores.primary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${formatarDistancia(r.distanciaMetros)} · '
                          '${r.tempoAPeMin} min a pé · '
                          '${r.tempoCarroMin} min de carro · '
                          'risco ${r.riscoNaVia.rotulo.toLowerCase()}',
                          style: TextStyle(color: cores.onSurfaceVariant),
                        ),
                        Row(children: [
                          Switch(
                            value: !r.interditada,
                            activeThumbColor: AppColors.seguro,
                            onChanged: (liberada) => executarComAviso(
                              context,
                              () => _servico.alterarInterdicao(r, !liberada),
                              sucesso: liberada
                                  ? 'Rota liberada.'
                                  : 'Rota interditada.',
                            ),
                          ),
                          Text(r.interditada ? 'Interditada' : 'Liberada'),
                          const Spacer(),
                          TextButton(
                              onPressed: () => _abrir(r),
                              child: const Text('Editar')),
                          TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: cores.error),
                            onPressed: () => _excluir(
                                r, nomes[r.abrigoId] ?? 'abrigo excluído'),
                            child: const Text('Excluir'),
                          ),
                        ]),
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

class TelaFormularioRota extends StatefulWidget {
  const TelaFormularioRota({super.key, this.rota});

  final RotaFuga? rota;

  @override
  State<TelaFormularioRota> createState() => _TelaFormularioRotaState();
}

class _TelaFormularioRotaState extends State<TelaFormularioRota> {
  late String? _abrigoId = widget.rota?.abrigoId;
  late List<LatLng> _pontos = [...?widget.rota?.pontos];
  late Gravidade _risco = widget.rota?.riscoNaVia ?? Gravidade.leve;
  late bool _interditada = widget.rota?.interditada ?? false;
  String? _erro;
  bool _salvando = false;

  Abrigo? get _abrigo {
    for (final a in AbrigosService.instance.cadastrados.value) {
      if (a.id == _abrigoId) return a;
    }
    return null;
  }

  Future<void> _salvar() async {
    final abrigo = _abrigo;
    if (abrigo == null) {
      setState(() => _erro = 'Escolha o abrigo de destino.');
      return;
    }
    if (_pontos.isEmpty) {
      setState(() => _erro = 'Marque o caminho no mapa.');
      return;
    }
    // O caminho termina sempre no abrigo.
    final pontos = [..._pontos];
    const d = Distance();
    if (d.as(LengthUnit.Meter, pontos.last, abrigo.localizacao) > 30) {
      pontos.add(abrigo.localizacao);
    }
    setState(() {
      _erro = null;
      _salvando = true;
    });
    try {
      await RotasFugaService.instance.salvar(RotasFugaService.montar(
        id: widget.rota?.id ?? '',
        abrigoId: abrigo.id,
        pontos: pontos,
        riscoNaVia: _risco,
        interditada: _interditada,
      ));
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
    final abrigos = AbrigosService.instance.cadastrados.value;
    final editando = widget.rota != null;
    final rotulo = const TextStyle(fontWeight: FontWeight.w600);
    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: AppBarTela(
        titulo: editando ? 'Editar rota' : 'Nova rota de fuga',
        ajuda: TextosAjuda.rotasFugaDefesaCivil,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (abrigos.isEmpty)
            Text(
                'Cadastre um abrigo no Painel antes de traçar a rota até ele.',
                style: TextStyle(color: cores.error))
          else
            DropdownButtonFormField<String>(
              initialValue:
                  abrigos.any((a) => a.id == _abrigoId) ? _abrigoId : null,
              decoration: const InputDecoration(labelText: 'Abrigo de destino'),
              items: [
                for (final a in abrigos)
                  DropdownMenuItem(value: a.id, child: Text(a.nome)),
              ],
              onChanged: (v) => setState(() => _abrigoId = v),
            ),
          const SizedBox(height: 16),
          Text('Caminho', style: rotulo),
          const SizedBox(height: 4),
          Text(
            'Toque no mapa do ponto de partida até o abrigo. O último ponto '
            'é ligado ao abrigo automaticamente.',
            style: TextStyle(fontSize: 13, color: cores.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          EditorPontosMapa(
            key: ValueKey(_abrigoId),
            pontos: _pontos,
            cor: AppColors.seguro,
            destino: _abrigo?.localizacao,
            aoMudar: (p) => setState(() => _pontos = p),
          ),
          const SizedBox(height: 12),
          Text('Risco no caminho', style: rotulo),
          const SizedBox(height: 8),
          Row(children: [
            for (final g in Gravidade.values) ...[
              if (g != Gravidade.values.first) const SizedBox(width: 10),
              Expanded(
                child: BotaoGravidade(
                  gravidade: g,
                  selecionada: _risco == g,
                  aoTocar: () => setState(() => _risco = g),
                ),
              ),
            ],
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rota interditada'),
            subtitle: const Text('Aparece em cinza para os moradores'),
            value: _interditada,
            onChanged: (v) => setState(() => _interditada = v),
          ),
          if (_erro != null) Text(_erro!, style: TextStyle(color: cores.error)),
          const SizedBox(height: 12),
          PrimaryButton(
            text: editando ? 'Salvar alterações' : 'Cadastrar rota',
            onPressed: abrigos.isEmpty ? null : _salvar,
            loading: _salvando,
          ),
        ],
      ),
    );
  }
}
