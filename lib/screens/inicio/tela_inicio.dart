import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../config.dart';
import '../../models/destino.dart';
import '../../models/models.dart';
import '../../services/abrigos_service.dart';
import '../../services/localizacao_service.dart';
import '../../services/perigos_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/modo_tema.dart';
import '../../utils/formatacao.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/faixa_alertas.dart';
import '../../widgets/mapa/botao_mapa.dart';
import '../../widgets/mapa/folha_reportar.dart';
import '../../widgets/mapa/mapa_enchente.dart';
import '../abrigos/tela_abrigos_proximos.dart';
import '../rota/tela_escolher_destino.dart';
import '../rota/tela_rota_fuga.dart';

/// Tela "01 Início" do protótipo: mapa ao vivo (posição do usuário e
/// alagamentos), atalhos de locais e os botões Abrigo e Rota de fuga.
class TelaInicio extends StatelessWidget {
  const TelaInicio({super.key});

  void _abrir(BuildContext context, Widget tela) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarTela(
        titulo: 'Início',
        acoesExtras: [BotaoModoTema()],
      ),
      body: Column(
        children: [
          const Expanded(child: _MapaInicio()),
          _PainelAcoes(
            aoAbrigo: () => _abrir(context, const TelaAbrigosProximos()),
            aoRotaFuga: () => _abrir(context, const TelaEscolherDestino()),
          ),
        ],
      ),
    );
  }
}

class _MapaInicio extends StatefulWidget {
  const _MapaInicio();

  @override
  State<_MapaInicio> createState() => _MapaInicioState();
}

class _MapaInicioState extends State<_MapaInicio> {
  final _controle = MapController();
  final _localizacao = LocalizacaoService.instance;
  bool _pronto = false;

  /// Como no Waze: o mapa acompanha a pessoa até ela arrastar o mapa.
  bool _seguir = true;

  @override
  void initState() {
    super.initState();
    PerigosService.instance.iniciar();
    _localizacao.iniciar();
    _localizacao.posicao.addListener(_aoMover);
  }

  @override
  void dispose() {
    _localizacao.posicao.removeListener(_aoMover);
    _controle.dispose();
    super.dispose();
  }

  void _aoMover() {
    final posicao = _localizacao.posicao.value;
    if (posicao == null || !_pronto || !_seguir) return;
    _controle.move(posicao.ponto, _controle.camera.zoom);
  }

  void _recentralizar() {
    setState(() => _seguir = true);
    final posicao = _localizacao.posicao.value;
    if (posicao != null && _pronto) _controle.move(posicao.ponto, 16.5);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapaEnchente(
          controller: _controle,
          zoomInicial: 16,
          aoFicarPronto: () {
            if (!mounted) return;
            _pronto = true;
            _aoMover();
          },
          aoMexerNoMapa: () {
            if (_seguir) setState(() => _seguir = false);
          },
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaixaAlertas(
                respeitarPreferencia: true,
                margem: EdgeInsets.only(bottom: 10),
              ),
              const _AtalhosLocais(),
              ValueListenableBuilder<PosicaoUsuario?>(
                valueListenable: _localizacao.posicao,
                builder: (context, posicao, _) {
                  if (posicao == null ||
                      !posicao.deTeste ||
                      Config.usarLocalizacaoDeTeste) {
                    return const SizedBox.shrink();
                  }
                  return _AvisoSemGps(
                    texto: _localizacao.problema ??
                        'Sem GPS: mostrando uma posição de exemplo.',
                  );
                },
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_seguir) ...[
                BotaoMapa(
                  icone: Icons.my_location,
                  dica: 'Voltar para minha posição',
                  aoTocar: _recentralizar,
                ),
                const SizedBox(height: 12),
              ],
              BotaoMapa(
                icone: Icons.campaign,
                dica: 'Reportar alagamento',
                cor: AppColors.alerta,
                corIcone: AppColors.azulMarinho,
                tamanho: 60,
                aoTocar: () => mostrarReportar(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvisoSemGps extends StatelessWidget {
  const _AvisoSemGps({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.alerta,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.gps_off, size: 18, color: AppColors.azulMarinho),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.azulMarinho,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra azul sobre o mapa com os 3 abrigos mais próximos, como os locais
/// do protótipo. Tocar num deles abre a rota de fuga até ele.
class _AtalhosLocais extends StatelessWidget {
  const _AtalhosLocais();

  @override
  Widget build(BuildContext context) {
    final abrigos = AbrigosService.instance..iniciar();
    final localizacao = LocalizacaoService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([abrigos.cadastrados, localizacao.posicao]),
      builder: (context, _) {
        final aqui = localizacao.posicao.value?.ponto;
        final perto = aqui == null
            ? const <Abrigo>[]
            : abrigos.porDistancia(aqui).take(3).toList();
        if (perto.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.azul,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.azulMarinho),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final a in perto)
                  _Atalho(
                    icone: Icons.home,
                    cor: AppColors.alerta,
                    texto: a.nome,
                    dica: 'Rota até ${a.nome}, ${formatarDistancia(a.distanciaAte(aqui!))}',
                    aoTocar: () => abrirRotaFuga(context, a.comoDestino),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Atalho extends StatelessWidget {
  const _Atalho({
    required this.icone,
    required this.cor,
    required this.texto,
    required this.dica,
    required this.aoTocar,
  });

  final IconData icone;
  final Color cor;
  final String texto;
  final String dica;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: dica,
      excludeSemantics: true,
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: _conteudo(),
        ),
      ),
    );
  }

  Widget _conteudo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 18, color: cor),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }
}

class _PainelAcoes extends StatelessWidget {
  const _PainelAcoes({required this.aoAbrigo, required this.aoRotaFuga});

  final VoidCallback aoAbrigo;
  final VoidCallback aoRotaFuga;

  @override
  Widget build(BuildContext context) {
    final estilo = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: estilo,
            onPressed: aoAbrigo,
            child: const Text('Abrigo'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: estilo,
            onPressed: aoRotaFuga,
            child: const Text('Rota de fuga'),
          ),
        ],
      ),
    );
  }
}
