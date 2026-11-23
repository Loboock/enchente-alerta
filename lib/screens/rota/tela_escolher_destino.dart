import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../config.dart';
import '../../data/dados_provisorios.dart';
import '../../models/destino.dart';
import '../../services/localizacao_service.dart';
import '../../services/rotas_service.dart';
import '../../utils/formatacao.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/cartao_local.dart';
import '../../widgets/scaffold_com_abas.dart';
import 'tela_rota_fuga.dart';

/// Texto do campo Partida quando a rota sai do GPS.
const textoSuaLocalizacao = 'Sua localização';

/// Tela para escolher de onde sair e para onde ir, no estilo do Uber: o
/// campo Partida fica em cima do Destino. Com a localização ativa, a
/// partida já vem preenchida com "Sua localização", mas dá para trocar por
/// outro endereço. Sem GPS, a partida fica vazia e é pedida antes de
/// calcular a rota (TelaRotaFuga), que desvia das áreas alagadas.
///
/// Os endereços vêm da busca do OpenRouteService (Pelias), priorizando os
/// que ficam perto da partida.
class TelaEscolherDestino extends StatefulWidget {
  const TelaEscolherDestino({super.key});

  @override
  State<TelaEscolherDestino> createState() => _TelaEscolherDestinoState();
}

class _TelaEscolherDestinoState extends State<TelaEscolherDestino> {
  /// Espera a pessoa parar de digitar antes de buscar (economiza a cota).
  static const _espera = Duration(milliseconds: 450);
  static const _minimoLetras = 3;

  final _campoPartida = TextEditingController();
  final _campoDestino = TextEditingController();
  final _focoPartida = FocusNode();
  final _focoDestino = FocusNode();
  final _localizacao = LocalizacaoService.instance;

  /// Texto da busca do campo que está sendo editado.
  String _busca = '';

  List<Destino> _enderecos = const [];
  bool _buscando = false;
  String? _erro;
  Timer? _timer;

  /// Para descartar respostas de buscas antigas.
  int _consulta = 0;

  /// Partida escolhida na busca; null = sair da localização atual (GPS).
  Destino? _partida;

  /// Destino escolhido antes de haver partida (sem GPS): a rota abre assim
  /// que a partida for escolhida.
  Destino? _destinoPendente;

  /// true = a busca vale para a partida; false = para o destino. Muda só
  /// quando um campo ganha o foco (perder o foco ao tocar num resultado
  /// não troca o alvo).
  bool _editandoPartida = false;

  /// O GPS não está disponível (permissão negada ou desligado).
  bool get _semGps =>
      !Config.usarLocalizacaoDeTeste &&
      (_localizacao.posicao.value?.deTeste ?? false);

  /// Já dá para calcular: tem partida escolhida ou o GPS.
  bool get _temPartida => _partida != null || !_semGps;

  /// De onde as distâncias são medidas: partida escolhida, GPS ou a
  /// posição de teste.
  LatLng get _origem =>
      _partida?.posicao ?? _localizacao.posicao.value?.ponto ?? usuarioProvisorio;

  @override
  void initState() {
    super.initState();
    _localizacao.iniciar();
    _localizacao.posicao.addListener(_aoMudarGps);
    _focoPartida.addListener(_aoTrocarCampo);
    _focoDestino.addListener(_aoTrocarCampo);
    _mostrarPartida();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _localizacao.posicao.removeListener(_aoMudarGps);
    _campoPartida.dispose();
    _campoDestino.dispose();
    _focoPartida.dispose();
    _focoDestino.dispose();
    super.dispose();
  }

  /// Escreve no campo Partida o que vale agora: o endereço escolhido,
  /// "Sua localização" ou vazio (sem GPS).
  void _mostrarPartida() {
    _campoPartida.text =
        _partida?.nome ?? (_semGps ? '' : textoSuaLocalizacao);
  }

  void _aoMudarGps() {
    if (!mounted) return;
    // O GPS pode responder depois que a tela abriu (ou falhar).
    if (!_editandoPartida) _mostrarPartida();
    setState(() {});
  }

  void _aoTrocarCampo() {
    if (!mounted) return;
    if (_focoPartida.hasFocus) {
      _editandoPartida = true;
    } else if (_focoDestino.hasFocus) {
      _editandoPartida = false;
    } else {
      return; // teclado fechado: mantém o alvo e o texto
    }
    if (_editandoPartida) {
      // Seleciona tudo: digitar já substitui "Sua localização".
      _campoPartida.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _campoPartida.text.length,
      );
    } else {
      // Saiu da partida sem escolher nada: volta ao que valia.
      _mostrarPartida();
    }
    _novaBusca(_editandoPartida ? '' : _campoDestino.text);
  }

  void _novaBusca(String texto) {
    _timer?.cancel();
    _consulta++;
    setState(() {
      _busca = texto;
      _erro = null;
      if (texto.trim().length < _minimoLetras) {
        _enderecos = const [];
        _buscando = false;
      }
    });
    if (texto.trim().length < _minimoLetras) return;
    _timer = Timer(_espera, () => _buscar(texto));
  }

  /// Enter no teclado: busca na hora, sem esperar.
  void _aoConfirmar(String texto) {
    _timer?.cancel();
    if (texto.trim().length >= _minimoLetras) _buscar(texto);
  }

  Future<void> _buscar(String texto) async {
    final consulta = ++_consulta;
    setState(() {
      _buscando = true;
      _erro = null;
    });
    List<Destino> achados = const [];
    String? erro;
    try {
      achados = await RotasService.instance.buscarEnderecos(
        texto,
        perto: _origem,
      );
    } on RotaException catch (e) {
      erro = e.mensagem;
    }
    if (!mounted || consulta != _consulta) return;
    setState(() {
      _enderecos = achados;
      _erro = erro;
      _buscando = false;
    });
  }

  /// Volta a partida para o GPS.
  void _usarMinhaLocalizacao() {
    setState(() => _partida = null);
    _mostrarPartida();
    _focoDestino.requestFocus();
  }

  void _limparDestino() {
    _campoDestino.clear();
    _destinoPendente = null;
    _novaBusca('');
  }

  void _aoTocarEndereco(Destino endereco) {
    if (_editandoPartida) {
      setState(() => _partida = endereco);
      _mostrarPartida();
      final pendente = _destinoPendente;
      if (pendente != null) {
        _destinoPendente = null;
        abrirRotaFuga(context, pendente, partida: endereco);
      } else {
        // Como no Uber: escolheu a partida, vai para o destino.
        _focoDestino.requestFocus();
      }
      return;
    }

    _campoDestino.text = endereco.nome;
    if (!_temPartida) {
      // Sem GPS não dá para saber de onde sair: pede a partida primeiro.
      _destinoPendente = endereco;
      _focoPartida.requestFocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Sem localização. Escolha de onde você vai sair.'),
          ),
        );
      return;
    }
    abrirRotaFuga(context, endereco, partida: _partida);
  }

  Widget _cartao(Destino destino) {
    return CartaoLocal(
      titulo: destino.nome,
      subtitulo: destino.detalhe ?? 'Endereço',
      icone: _editandoPartida ? Icons.trip_origin : Icons.location_on_outlined,
      distancia: formatarDistancia(metrosEntre(_origem, destino.posicao)),
      aoTocar: () => _aoTocarEndereco(destino),
    );
  }

  /// Os dois campos, um em cima do outro, ligados por uma linha.
  Widget _campos() {
    final cores = Theme.of(context).colorScheme;
    final partidaGps = _partida == null && !_semGps && !_editandoPartida;

    final Widget? botaoPartida;
    if (!_semGps && (_partida != null || _editandoPartida)) {
      botaoPartida = IconButton(
        tooltip: 'Usar minha localização',
        icon: const Icon(Icons.my_location),
        onPressed: _usarMinhaLocalizacao,
      );
    } else {
      botaoPartida = null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 0),
      child: Row(
        children: [
          // Bolinha da partida, linha e pino do destino.
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Icon(Icons.trip_origin, size: 18, color: cores.primary),
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: cores.outline,
                ),
                const Icon(Icons.location_on, size: 20, color: Colors.green),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                TextField(
                  key: const Key('campo-partida'),
                  controller: _campoPartida,
                  focusNode: _focoPartida,
                  onChanged: _novaBusca,
                  onSubmitted: _aoConfirmar,
                  textInputAction: TextInputAction.search,
                  style: partidaGps
                      ? TextStyle(
                          color: cores.primary,
                          fontWeight: FontWeight.w600,
                        )
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Partida',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: _semGps
                        ? 'Sem localização: digite a partida'
                        : 'De onde você vai sair?',
                    hintStyle: _semGps ? TextStyle(color: cores.error) : null,
                    suffixIcon: botaoPartida,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('campo-destino'),
                  controller: _campoDestino,
                  focusNode: _focoDestino,
                  onChanged: _novaBusca,
                  onSubmitted: _aoConfirmar,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Destino',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: 'Endereço de destino',
                    suffixIcon: _campoDestino.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar',
                            icon: const Icon(Icons.close),
                            onPressed: _limparDestino,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ícone grande com um texto no meio da tela (orientação, erro, vazio).
  Widget _mensagem(IconData icone, String texto, {Color? cor}) {
    final cores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
      child: Column(
        children: [
          Icon(icone, size: 56, color: cor ?? cores.primary),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(color: cor ?? cores.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  List<Widget> _conteudo() {
    final cores = Theme.of(context).colorScheme;
    final erro = _erro;

    if (!RotasService.instance.buscaDisponivel) {
      return [
        _mensagem(
          Icons.key_off,
          'Falta a chave do OpenRouteService. Veja docs/rotas-e-mapa.md.',
          cor: cores.error,
        ),
      ];
    }
    if (_busca.trim().length < _minimoLetras) {
      return [
        _editandoPartida
            ? _mensagem(
                Icons.trip_origin,
                'Digite o endereço de onde você vai sair.',
              )
            : _mensagem(
                Icons.alt_route,
                'Digite o endereço para onde você quer ir.\n'
                'A rota desvia das áreas alagadas.',
              ),
      ];
    }
    if (_buscando && _enderecos.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (erro != null) {
      return [_mensagem(Icons.wifi_off, erro, cor: cores.error)];
    }
    if (_enderecos.isEmpty) {
      return [
        _mensagem(
          Icons.search_off,
          'Nenhum endereço encontrado.\nTente incluir o bairro ou a cidade.',
        ),
      ];
    }
    return [
      if (_buscando) const LinearProgressIndicator(),
      for (final endereco in _enderecos) _cartao(endereco),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldComAbas(
      appBar: const AppBarTela(
        titulo: 'Rota de fuga',
        subtitulo: 'Para onde você quer ir?',
        ajuda: TextosAjuda.escolherDestino,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _campos(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: _conteudo(),
            ),
          ),
        ],
      ),
    );
  }
}
