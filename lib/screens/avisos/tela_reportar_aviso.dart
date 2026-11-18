import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/perigos_service.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../../widgets/widgets_conta.dart';

/// Abre a tela "Reportar aviso" de [ocorrencia]. Devolve true quando a
/// denúncia foi enviada.
Future<bool?> abrirReportarAviso(BuildContext context, Ocorrencia ocorrencia) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => TelaReportarAviso(ocorrencia: ocorrencia),
    ),
  );
}

/// Tela "06 Reportar aviso" do protótipo: a pessoa diz o que está errado no
/// aviso (4 motivos + detalhes opcionais). Vira uma denúncia que só a Defesa
/// Civil lê; cada pessoa denuncia o mesmo aviso uma vez.
class TelaReportarAviso extends StatefulWidget {
  const TelaReportarAviso({super.key, required this.ocorrencia});

  final Ocorrencia ocorrencia;

  @override
  State<TelaReportarAviso> createState() => _TelaReportarAvisoState();
}

class _TelaReportarAvisoState extends State<TelaReportarAviso> {
  MotivoDenuncia _motivo = MotivoDenuncia.informacaoIncorreta;
  final _detalhes = TextEditingController();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _detalhes.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await PerigosService.instance.denunciar(
        widget.ocorrencia,
        motivo: _motivo,
        detalhes: _detalhes.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PerigoException catch (e) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _erro = e.mensagem;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final o = widget.ocorrencia;
    final resumo = '${o.endereco} · '
        '${o.tipo.rotulo} ${o.gravidade.rotulo.toLowerCase()}';

    return ScaffoldComAbas(
      abaAtiva: 1,
      appBar: const AppBarTela(
        titulo: 'Reportar aviso',
        ajuda: TextosAjuda.reportarAviso,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Você está reportando',
              style: TextStyle(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cores.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cores.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVISO SELECIONADO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cores.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resumo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cores.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                'Qual o problema com esse aviso?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cores.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            RadioGroup<MotivoDenuncia>(
              groupValue: _motivo,
              onChanged: (m) {
                if (m != null) setState(() => _motivo = m);
              },
              child: Column(
                children: [
                  for (final m in MotivoDenuncia.values)
                    RadioListTile<MotivoDenuncia>(
                      value: m,
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.rotulo),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Detalhes (opcional)',
              style: TextStyle(
                color: cores.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _detalhes,
              maxLength: 500,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Descreva o que está errado...',
                hintStyle: TextStyle(color: cores.onSurfaceVariant),
              ),
            ),
            if (_erro case final erro?)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(erro, style: TextStyle(color: cores.error)),
              ),
            const SizedBox(height: 4),
            PrimaryButton(
              text: 'Enviar denúncia',
              onPressed: _enviar,
              loading: _enviando,
            ),
          ],
        ),
      ),
    );
  }
}
