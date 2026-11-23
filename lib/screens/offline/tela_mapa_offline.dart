import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../services/conexao_service.dart';
import '../../services/localizacao_service.dart';
import '../../services/mapa_offline_service.dart';
import '../../utils/formatacao.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../../widgets/widgets_conta.dart';

/// Centro de Aracaju, usado quando não há localização.
const _centroPadrao = LatLng(-10.9472, -37.0731);

/// "Mapa sem internet" (RF07, RNF05): guarda o mapa dos arredores para
/// consultar o mapa, os avisos e os abrigos mesmo sem conexão.
class TelaMapaOffline extends StatefulWidget {
  const TelaMapaOffline({super.key, this.abaAtiva = -1});

  final int abaAtiva;

  @override
  State<TelaMapaOffline> createState() => _TelaMapaOfflineState();
}

class _TelaMapaOfflineState extends State<TelaMapaOffline> {
  final _servico = MapaOfflineService.instance;
  int? _bytes;

  @override
  void initState() {
    super.initState();
    _servico.carregarRegiao();
    _medir();
  }

  Future<void> _medir() async {
    final b = await _servico.tamanho();
    if (mounted) setState(() => _bytes = b);
  }

  LatLng get _centro =>
      LocalizacaoService.instance.posicao.value?.ponto ?? _centroPadrao;

  Future<void> _salvar() async {
    final falhas = await _servico.salvarRegiao(_centro);
    await _medir();
    if (!mounted) return;
    showMsg(
      context,
      falhas == 0
          ? 'Mapa da região salvo. Ele funciona mesmo sem internet.'
          : 'Parte do mapa não foi salva ($falhas pedaços). Tente de novo '
              'com uma conexão melhor.',
    );
  }

  Future<void> _apagar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar o mapa guardado?'),
        content: const Text(
            'Sem internet, o mapa vai aparecer em branco até ser salvo de novo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apagar')),
        ],
      ),
    );
    if (ok != true) return;
    await _servico.limpar();
    await _medir();
    if (mounted) showMsg(context, 'Mapa guardado apagado.');
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final pedacos = MapaOfflineService.pedacosDaRegiao(_centro).length *
        FonteMapa.paraGuardar.length;
    final usaGps = LocalizacaoService.instance.posicao.value != null;

    return ScaffoldComAbas(
      abaAtiva: widget.abaAtiva,
      appBar: barraConta(context, 'Mapa sem internet',
          ajuda: TextosAjuda.mapaOffline),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.download_for_offline_outlined,
              size: 56, color: cores.primary),
          const SizedBox(height: 12),
          Text(
            'Salve o mapa antes da chuva',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cores.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Guarda no aparelho o mapa de cerca de '
            '${MapaOfflineService.raioPadraoKm.toStringAsFixed(0)} km em volta '
            '${usaGps ? 'de onde você está' : 'do centro de Aracaju'}. '
            'Sem internet, você continua vendo o mapa, os últimos avisos, os '
            'abrigos e o histórico. O mapa que você já abriu também fica '
            'guardado automaticamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cores.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder(
            valueListenable: _servico.regiaoSalva,
            builder: (context, regiao, _) => _Linha(
              icone: Icons.map_outlined,
              rotulo: 'Região salva',
              valor: regiao == null
                  ? 'Nenhuma ainda'
                  : 'Em ${formatarDataCurta(regiao.em)}, perto de '
                      '${formatarCoordenada(regiao.centro)}',
            ),
          ),
          _Linha(
            icone: Icons.sd_storage_outlined,
            rotulo: 'Espaço usado no aparelho',
            valor: _bytes == null ? '...' : _tamanho(_bytes!),
          ),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: Listenable.merge(
                [_servico.progresso, ConexaoService.instance.online]),
            builder: (context, _) {
              final p = _servico.progresso.value;
              final online = ConexaoService.instance.online.value;
              if (p != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(value: p.fracao),
                    const SizedBox(height: 8),
                    Text(
                      'Salvando ${p.feitos} de ${p.total} partes do mapa...',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _servico.cancelar,
                      child: const Text('Cancelar'),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    text: 'Salvar mapa da região',
                    onPressed: online ? _salvar : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    online
                        ? 'São cerca de $pedacos partes. Use o Wi-Fi se puder.'
                        : 'Conecte-se à internet para salvar o mapa.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: cores.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: (_bytes ?? 0) > 0 ? _apagar : null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Apagar o mapa guardado'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

String _tamanho(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
}

class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.rotulo, required this.valor});

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icone, color: cores.primary),
      title: Text(rotulo,
          style: TextStyle(fontSize: 13, color: cores.onSurfaceVariant)),
      subtitle: Text(valor,
          style: TextStyle(fontSize: 16, color: cores.onSurface)),
    );
  }
}
