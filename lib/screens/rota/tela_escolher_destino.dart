import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../data/dados_provisorios.dart';
import '../../models/destino.dart';
import '../../services/localizacao_service.dart';
import '../../services/rotas_service.dart';
import '../../utils/formatacao.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/cartao_local.dart';
import '../../widgets/scaffold_com_abas.dart';
import 'tela_rota_fuga.dart';

/// Tela para escolher o destino da rota de fuga: a pessoa digita um
/// endereço, escolhe uma das sugestões e o app calcula a rota que desvia
/// das áreas alagadas (TelaRotaFuga).
///
/// Os endereços vêm da busca do OpenRouteService (Pelias), priorizando os
/// que ficam perto da posição atual.
class TelaEscolherDestino extends StatefulWidget {
  const TelaEscolherDestino({super.key});

  @override
  State<TelaEscolherDestino> createState() => _TelaEscolherDestinoState();
}

class _TelaEscolherDestinoState extends State<TelaEscolherDestino> {
  /// Espera a pessoa parar de digitar antes de buscar (economiza a cota).
  static const _espera = Duration(milliseconds: 450);
  static const _minimoLetras = 3;

  final _controlador = TextEditingController();
  String _busca = '';

  List<Destino> _enderecos = const [];
  bool _buscando = false;
  String? _erro;
  Timer? _timer;

  /// Para descartar respostas de buscas antigas.
  int _consulta = 0;

  /// De onde as distâncias são medidas: GPS ou a posição de teste.
  LatLng get _origem =>
      LocalizacaoService.instance.posicao.value?.ponto ?? usuarioProvisorio;

  @override
  void initState() {
    super.initState();
    LocalizacaoService.instance.iniciar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  void _aoDigitar(String texto) {
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

  void _limpar() {
    _controlador.clear();
    _aoDigitar('');
  }

  Widget _cartao(Destino destino) {
    return CartaoLocal(
      titulo: destino.nome,
      subtitulo: destino.detalhe ?? 'Endereço',
      icone: Icons.location_on_outlined,
      distancia: formatarDistancia(metrosEntre(_origem, destino.posicao)),
      aoTocar: () => abrirRotaFuga(context, destino),
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
        _mensagem(
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
    final cores = Theme.of(context).colorScheme;
    final digitando = _busca.isNotEmpty;

    return ScaffoldComAbas(
      appBar: const AppBarTela(
        titulo: 'Rota de fuga',
        subtitulo: 'Para onde você quer ir?',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: TextField(
              controller: _controlador,
              onChanged: _aoDigitar,
              onSubmitted: _aoConfirmar,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Digite um endereço',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: digitando
                    ? IconButton(
                        tooltip: 'Limpar',
                        icon: const Icon(Icons.close),
                        onPressed: _limpar,
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 20, 0),
            child: Row(
              children: [
                Icon(Icons.my_location, size: 16, color: cores.primary),
                const SizedBox(width: 6),
                Text(
                  'Saindo da sua localização atual',
                  style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            // Refaz as distâncias quando o GPS atualiza.
            child: ValueListenableBuilder<PosicaoUsuario?>(
              valueListenable: LocalizacaoService.instance.posicao,
              builder: (context, posicao, child) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: _conteudo(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
