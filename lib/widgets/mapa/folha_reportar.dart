import 'package:flutter/material.dart';

import '../../config.dart';
import '../../models/models.dart';
import '../../services/localizacao_service.dart';
import '../../services/perigos_service.dart';
import '../../services/rotas_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/exigir_login.dart';

/// Botão "Reportar" do mapa, como no Waze: a pessoa diz o que está vendo e
/// o aviso é criado onde ela está.
Future<void> mostrarReportar(BuildContext context) async {
  if (!exigirLogin(context)) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FolhaReportar(contextoTela: context),
  );
}

class _FolhaReportar extends StatefulWidget {
  const _FolhaReportar({required this.contextoTela});

  final BuildContext contextoTela;

  @override
  State<_FolhaReportar> createState() => _FolhaReportarState();
}

class _FolhaReportarState extends State<_FolhaReportar> {
  TipoOcorrencia _tipo = TipoOcorrencia.alagamento;
  Gravidade _gravidade = Gravidade.moderado;
  double _nivelAguaCm = 30;
  final _descricao = TextEditingController();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final posicao = await LocalizacaoService.instance.atual();
      // Sem GPS de verdade o aviso cairia no lugar errado.
      if (posicao.deTeste && !Config.usarLocalizacaoDeTeste) {
        throw PerigoException(
          LocalizacaoService.instance.problema ??
              'Não conseguimos sua localização. Ative o GPS.',
        );
      }
      final endereco = await RotasService.instance.enderecoDe(posicao.ponto) ??
          'Perto de ${posicao.ponto.latitude.toStringAsFixed(5)}, '
              '${posicao.ponto.longitude.toStringAsFixed(5)}';
      await PerigosService.instance.reportar(
        tipo: _tipo,
        gravidade: _gravidade,
        local: posicao.ponto,
        endereco: endereco,
        nivelAguaCm:
            _tipo == TipoOcorrencia.alagamento ? _nivelAguaCm.round() : 0,
        descricao: _descricao.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      final tela = widget.contextoTela;
      if (tela.mounted) {
        ScaffoldMessenger.of(tela)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Aviso enviado! Quando mais alguém confirmar, as rotas '
                'passam a desviar deste ponto.',
              ),
            ),
          );
      }
    } on PerigoException catch (e) {
      setState(() {
        _enviando = false;
        _erro = e.mensagem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final teclado = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + teclado),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'O que você está vendo?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'O aviso é criado na sua localização atual.',
              style: TextStyle(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OpcaoTipo(
                    icone: Icons.water_drop,
                    texto: 'Alagamento',
                    selecionado: _tipo == TipoOcorrencia.alagamento,
                    aoTocar: () =>
                        setState(() => _tipo = TipoOcorrencia.alagamento),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OpcaoTipo(
                    icone: Icons.block,
                    texto: 'Via obstruída',
                    selecionado: _tipo == TipoOcorrencia.viaObstruida,
                    aoTocar: () =>
                        setState(() => _tipo = TipoOcorrencia.viaObstruida),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Gravidade', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<Gravidade>(
              segments: [
                for (final g in Gravidade.values)
                  ButtonSegment(value: g, label: Text(g.rotulo)),
              ],
              selected: {_gravidade},
              onSelectionChanged: (s) => setState(() => _gravidade = s.first),
            ),
            if (_tipo == TipoOcorrencia.alagamento) ...[
              const SizedBox(height: 20),
              Text(
                'Altura da água: ${_nivelAguaCm.round()} cm',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _nivelAguaCm,
                max: 150,
                divisions: 15,
                label: '${_nivelAguaCm.round()} cm',
                onChanged: (v) => setState(() => _nivelAguaCm = v),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _descricao,
              maxLength: 140,
              decoration: const InputDecoration(
                hintText: 'Detalhe (opcional)',
              ),
            ),
            if (_erro case final erro?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(erro, style: TextStyle(color: cores.error)),
              ),
            Text(
              'Seu nome não aparece no aviso. As rotas só desviam depois de '
              '${Config.confirmacoesParaBloquear} confirmações.',
              style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _enviando
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alerta,
                      foregroundColor: AppColors.azulMarinho,
                    ),
                    onPressed: _enviar,
                    icon: const Icon(Icons.campaign),
                    label: const Text('Enviar aviso'),
                  ),
          ],
        ),
      ),
    );
  }
}

class _OpcaoTipo extends StatelessWidget {
  const _OpcaoTipo({
    required this.icone,
    required this.texto,
    required this.selecionado,
    required this.aoTocar,
  });

  final IconData icone;
  final String texto;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Semantics(
      selected: selecionado,
      button: true,
      child: Material(
        color: selecionado ? cores.primaryContainer : cores.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selecionado ? cores.primary : cores.outline,
            width: selecionado ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icone, size: 32, color: cores.primary),
                const SizedBox(height: 6),
                Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
