import 'package:flutter/material.dart';

import '../../models/perigo.dart';
import '../../services/perigos_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/exigir_login.dart';
import 'mapa_enchente.dart';

/// Detalhes de um alagamento tocado no mapa. Nos avisos da comunidade tem
/// os botões do Waze: "Ainda está aí" e "Não está mais".
Future<void> mostrarDetalhesPerigo(BuildContext context, Perigo perigo) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _FolhaPerigo(perigo: perigo, contextoTela: context),
  );
}

class _FolhaPerigo extends StatefulWidget {
  const _FolhaPerigo({required this.perigo, required this.contextoTela});

  final Perigo perigo;

  /// Contexto da tela por baixo, para o aviso continuar depois que a folha
  /// fecha.
  final BuildContext contextoTela;

  @override
  State<_FolhaPerigo> createState() => _FolhaPerigoState();
}

class _FolhaPerigoState extends State<_FolhaPerigo> {
  bool _enviando = false;

  Future<void> _responder({required bool aindaEsta}) async {
    final ocorrencia = widget.perigo.ocorrencia;
    if (ocorrencia == null) return;
    if (!exigirLogin(widget.contextoTela, acao: 'confirmar avisos')) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _enviando = true);
    String mensagem;
    try {
      if (aindaEsta) {
        await PerigosService.instance.confirmar(ocorrencia);
        mensagem = 'Obrigado! Confirmação registrada.';
      } else {
        await PerigosService.instance.negar(ocorrencia);
        mensagem = 'Obrigado! A Defesa Civil vai revisar este aviso.';
      }
    } on PerigoException catch (e) {
      mensagem = e.mensagem;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    final tela = widget.contextoTela;
    if (tela.mounted) {
      ScaffoldMessenger.of(tela)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.perigo;
    final cores = Theme.of(context).colorScheme;
    final ocorrencia = p.ocorrencia;
    final corDestaque = p.bloqueia ? AppColors.perigo : AppColors.alerta;

    final String situacao;
    if (!p.daComunidade) {
      situacao = 'Área oficial: as rotas sempre desviam dela.';
    } else if (p.bloqueia) {
      situacao = 'Confirmado por ${ocorrencia!.confirmacoes} pessoas: '
          'as rotas desviam deste ponto.';
    } else {
      final faltam = p.faltamConfirmacoes;
      situacao = 'Aguardando confirmação: falta${faltam == 1 ? '' : 'm'} '
          '$faltam para as rotas desviarem.';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: corDestaque,
                  foregroundColor: Colors.white,
                  child: Icon(iconeDoPerigo(p)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Gravidade ${p.gravidade.rotulo.toLowerCase()}'
                        '${p.daComunidade ? ' · aviso de morador' : ' · Defesa Civil'}',
                        style: TextStyle(color: cores.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(p.detalhe),
            if (ocorrencia != null && ocorrencia.nivelAguaCm > 0)
              Text('Nível da água: cerca de ${ocorrencia.nivelAguaCm} cm'),
            if (ocorrencia?.descricao case final descricao?)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('"$descricao"'),
              ),
            const SizedBox(height: 8),
            Text(
              situacao,
              style: TextStyle(
                color: corDestaque,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (ocorrencia != null) ...[
              const SizedBox(height: 16),
              if (_enviando)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _responder(aindaEsta: false),
                        child: const Text('Não está mais'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _responder(aindaEsta: true),
                        child: const Text('Ainda está aí'),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
