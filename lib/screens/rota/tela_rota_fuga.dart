import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../config.dart';
import '../../models/destino.dart';
import '../../models/perigo.dart';
import '../../models/rota_calculada.dart';
import '../../services/localizacao_service.dart';
import '../../services/perigos_service.dart';
import '../../services/rotas_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatacao.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/mapa/mapa_enchente.dart';
import '../../widgets/scaffold_com_abas.dart';
import 'tela_navegacao.dart';

/// Abre a rota de fuga até [destino], saindo de [partida] (ou da
/// localização atual, se for null).
void abrirRotaFuga(BuildContext context, Destino destino, {Destino? partida}) {
  FocusScope.of(context).unfocus();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TelaRotaFuga(destino: destino, partida: partida),
    ),
  );
}

/// Cores da linha da rota (azul do Waze, com borda escura).
const corRota = Color(0xFF3FA2F7);
const corBordaRota = Color(0xFF1A4D8F);

/// Linha da rota no estilo do Waze.
Polyline<Object> linhaRota(List<LatLng> pontos) => Polyline(
  points: pontos,
  strokeWidth: 8,
  color: corRota,
  borderStrokeWidth: 2.5,
  borderColor: corBordaRota,
);

/// Bolinha azul do ponto de partida escolhido.
Marker marcaPartida(LatLng ponto) => Marker(
  point: ponto,
  width: 22,
  height: 22,
  child: Container(
    decoration: BoxDecoration(
      color: corRota,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
    ),
  ),
);

/// Pino verde do destino.
Marker pinoDestino(LatLng ponto) => Marker(
  point: ponto,
  width: 44,
  height: 44,
  // A ponta do pino fica sobre o ponto.
  alignment: Alignment.topCenter,
  child: const Icon(
    Icons.location_on,
    color: AppColors.seguro,
    size: 44,
    shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
  ),
);

/// Tela "02 Rota de fuga" do protótipo: rota real até o destino, desviando
/// dos alagamentos, com tempo, distância e o botão de navegação.
class TelaRotaFuga extends StatefulWidget {
  const TelaRotaFuga({super.key, required this.destino, this.partida});

  final Destino destino;

  /// Ponto de partida escolhido; null = localização atual (GPS).
  final Destino? partida;

  @override
  State<TelaRotaFuga> createState() => _TelaRotaFugaState();
}

class _TelaRotaFugaState extends State<TelaRotaFuga> {
  final _controle = MapController();
  final _perigos = PerigosService.instance.perigos;
  bool _mapaPronto = false;

  ModoTransporte _modo = ModoTransporte.carro;
  final _rotas = <ModoTransporte, RotaCalculada>{};
  PosicaoUsuario? _origem;
  bool _carregando = true;
  String? _erro;

  /// Para ignorar a resposta de um cálculo antigo (ex.: trocou o modo).
  int _pedido = 0;

  RotaCalculada? get _rota => _rotas[_modo];

  /// Sem acompanhar o GPS (partida escolhida ou localização negada), a
  /// navegação mostra a rota passo a passo.
  bool get _passoAPasso =>
      widget.partida != null ||
      (!Config.usarLocalizacaoDeTeste && (_origem?.deTeste ?? false));

  @override
  void initState() {
    super.initState();
    PerigosService.instance.iniciar();
    _perigos.addListener(_aoMudarPerigos);
    _calcular();
  }

  @override
  void dispose() {
    _perigos.removeListener(_aoMudarPerigos);
    _controle.dispose();
    super.dispose();
  }

  Future<void> _calcular() async {
    final pedido = ++_pedido;
    final modo = _modo;
    // Na primeira chamada (initState) o estado já começa "carregando".
    if (!_carregando || _erro != null) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final partida = widget.partida;
      final origem = partida != null
          ? PosicaoUsuario(ponto: partida.posicao)
          : await LocalizacaoService.instance.atual();
      final rota = await RotasService.instance.calcular(
        origem: origem.ponto,
        destino: widget.destino.posicao,
        modo: modo,
        perigos: _perigos.value,
      );
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _origem = origem;
        _rotas[modo] = rota;
        _carregando = false;
      });
      _enquadrar();
    } on RotaException catch (e) {
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    }
  }

  void _trocarModo(ModoTransporte modo) {
    if (modo == _modo) return;
    setState(() => _modo = modo);
    if (_rotas[modo] == null) {
      _calcular();
    } else {
      _pedido++; // descarta um cálculo do outro modo que ainda esteja em curso
      setState(() {
        _carregando = false;
        _erro = null;
      });
      _enquadrar();
    }
  }

  /// Um alagamento novo foi confirmado em cima da rota: calcula de novo.
  void _aoMudarPerigos() {
    final rota = _rota;
    if (rota == null || _carregando) return;
    final bloqueiaAgora = _perigos.value.any(
      (p) =>
          p.bloqueia &&
          !rota.perigosInevitaveis.any((x) => x.id == p.id) &&
          p.cruza(rota.pontos),
    );
    if (!bloqueiaAgora) return;
    _rotas.clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Novo alagamento no caminho. Recalculando a rota...'),
        ),
      );
    _calcular();
  }

  void _enquadrar() {
    final rota = _rota;
    if (!_mapaPronto || rota == null || rota.pontos.isEmpty) return;
    _controle.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([
          ...rota.pontos,
          widget.destino.posicao,
        ]),
        // Espaço embaixo para o painel.
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 330),
        maxZoom: 17,
      ),
    );
  }

  void _iniciarNavegacao() {
    final rota = _rota;
    if (rota == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaNavegacao(
          destino: widget.destino,
          rota: rota,
          passoAPasso: _passoAPasso,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rota = _rota;

    return ScaffoldComAbas(
      appBar: AppBarTela(
        titulo: 'Rota de fuga',
        subtitulo: 'Menor risco até ${widget.destino.nome}',
        ajuda: TextosAjuda.rotaFuga,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MapaEnchente(
            controller: _controle,
            centroInicial: widget.destino.posicao,
            zoomInicial: 15,
            aoFicarPronto: () {
              if (!mounted) return;
              _mapaPronto = true;
              _enquadrar();
            },
            camadasExtras: [
              if (rota != null)
                PolylineLayer(polylines: [linhaRota(rota.pontos)]),
              MarkerLayer(
                markers: [
                  if (widget.partida case final partida?)
                    marcaPartida(partida.posicao),
                  pinoDestino(widget.destino.posicao),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            child: _PainelRota(
              modo: _modo,
              rota: rota,
              origem: _origem,
              partidaEscolhida: widget.partida != null,
              passoAPasso: _passoAPasso,
              carregando: _carregando,
              erro: _erro,
              aoTrocarModo: _trocarModo,
              aoTentarDeNovo: _calcular,
              aoIniciar: _iniciarNavegacao,
              // Volta para a escolha de partida e destino (ou para a lista
              // de abrigos), com o que já estava preenchido.
              aoCancelar: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// "22:41" (hora de chegada).
String horaDeChegada(double segundosRestantes) {
  final chegada = DateTime.now().add(
    Duration(seconds: segundosRestantes.round()),
  );
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(chegada.hour)}:${dois(chegada.minute)}';
}

String _plural(int n, String singular, String plural) =>
    '$n ${n == 1 ? singular : plural}';

class _PainelRota extends StatelessWidget {
  const _PainelRota({
    required this.modo,
    required this.rota,
    required this.origem,
    required this.partidaEscolhida,
    required this.passoAPasso,
    required this.carregando,
    required this.erro,
    required this.aoTrocarModo,
    required this.aoTentarDeNovo,
    required this.aoIniciar,
    required this.aoCancelar,
  });

  final ModoTransporte modo;
  final RotaCalculada? rota;
  final PosicaoUsuario? origem;

  /// A rota sai de um ponto escolhido, não da posição da pessoa.
  final bool partidaEscolhida;

  /// A navegação vai ser passo a passo (sem acompanhar o GPS).
  final bool passoAPasso;
  final bool carregando;
  final String? erro;
  final ValueChanged<ModoTransporte> aoTrocarModo;
  final VoidCallback aoTentarDeNovo;
  final VoidCallback aoIniciar;
  final VoidCallback aoCancelar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final rota = this.rota;
    final erro = this.erro;

    final botaoCancelar = OutlinedButton(
      onPressed: aoCancelar,
      child: const Text('Cancelar'),
    );

    final Widget conteudo;
    if (carregando) {
      conteudo = Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            const Text(
              'Calculando a rota mais segura...',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            botaoCancelar,
          ],
        ),
      );
    } else if (erro != null || rota == null) {
      conteudo = Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: cores.error),
                const SizedBox(width: 8),
                Expanded(child: Text(erro ?? 'Rota indisponível.')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: botaoCancelar),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: aoTentarDeNovo,
                    child: const Text('Tentar de novo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      conteudo = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Dado(
                valor: '${rota.duracaoMin} min',
                rotulo: modo.rotulo.toLowerCase(),
              ),
              _Dado(
                valor: formatarDistancia(rota.distanciaMetros, compacto: true),
                rotulo: 'distância',
              ),
              _Dado(valor: horaDeChegada(rota.duracaoSeg), rotulo: 'chegada'),
            ],
          ),
          const SizedBox(height: 12),
          ..._avisos(context, rota),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: aoIniciar,
            icon: const Icon(Icons.navigation),
            label: const Text('Iniciar navegação'),
          ),
          const SizedBox(height: 8),
          botaoCancelar,
        ],
      );
    }

    return Material(
      color: cores.surface,
      elevation: 6,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<ModoTransporte>(
              segments: const [
                ButtonSegment(
                  value: ModoTransporte.carro,
                  icon: Icon(Icons.directions_car),
                  label: Text('Carro'),
                ),
                ButtonSegment(
                  value: ModoTransporte.aPe,
                  icon: Icon(Icons.directions_walk),
                  label: Text('A pé'),
                ),
              ],
              selected: {modo},
              onSelectionChanged: (s) => aoTrocarModo(s.first),
            ),
            const SizedBox(height: 8),
            conteudo,
          ],
        ),
      ),
    );
  }

  List<Widget> _avisos(BuildContext context, RotaCalculada rota) {
    final cores = Theme.of(context).colorScheme;
    final evitados = rota.perigosEvitados.length;
    final naoConfirmados = rota.avisosNoCaminho.length;
    final origem = this.origem;

    return [
      _LinhaAviso(
        icone: Icons.verified_user,
        cor: AppColors.seguro,
        texto: evitados == 0
            ? 'Nenhum alagamento confirmado no caminho.'
            : 'Desvia de ${_plural(evitados, 'alagamento', 'alagamentos')}.',
      ),
      if (naoConfirmados > 0)
        _LinhaAviso(
          icone: Icons.warning_amber,
          cor: AppColors.alerta,
          texto:
              '${_plural(naoConfirmados, 'aviso', 'avisos')} ainda sem '
              'confirmação no caminho. Fique atento.',
        ),
      for (final p in rota.perigosInevitaveis)
        _LinhaAviso(
          icone: Icons.dangerous,
          cor: cores.error,
          texto: _textoInevitavel(p, origem),
        ),
      if (passoAPasso)
        _LinhaAviso(
          icone: Icons.format_list_numbered,
          cor: cores.onSurfaceVariant,
          texto: partidaEscolhida
              ? 'Saindo do ponto escolhido: a navegação mostra uma manobra '
                    'por vez e você avança com "Próxima".'
              : 'Sem GPS: a navegação mostra uma manobra por vez e você '
                    'avança com "Próxima".',
        ),
      if (origem != null && origem.deTeste && !partidaEscolhida)
        _LinhaAviso(
          icone: Icons.gps_off,
          cor: cores.onSurfaceVariant,
          texto: 'Sem GPS: saindo de uma posição de exemplo.',
        ),
    ];
  }

  String _textoInevitavel(Perigo p, PosicaoUsuario? origem) {
    if (origem != null && p.contem(origem.ponto)) {
      return partidaEscolhida
          ? 'A partida fica numa área de risco (${p.titulo}).'
          : 'Você está numa área de risco (${p.titulo}). Saia com cuidado.';
    }
    return 'O destino fica numa área de risco (${p.titulo}).';
  }
}

class _LinhaAviso extends StatelessWidget {
  const _LinhaAviso({
    required this.icone,
    required this.cor,
    required this.texto,
  });

  final IconData icone;
  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

/// Um número em destaque com o rótulo pequeno embaixo.
class _Dado extends StatelessWidget {
  const _Dado({required this.valor, required this.rotulo});

  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cores.primary,
            ),
          ),
          Text(
            rotulo,
            style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
