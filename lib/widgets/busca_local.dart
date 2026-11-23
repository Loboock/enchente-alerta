import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/destino.dart';
import '../services/localizacao_service.dart';
import '../services/rotas_service.dart';
import '../utils/formatacao.dart';

/// Escolha de um local: busca de endereço com sugestões ou "Usar minha
/// posição atual". Usado no cadastro de endereços.
class BuscaLocal extends StatefulWidget {
  const BuscaLocal({
    super.key,
    required this.aoEscolher,
    this.local,
    this.descricao,
    this.dica = 'Buscar endereço',
    this.erro,
  });

  /// Chamado com o ponto, o nome curto e o endereço completo.
  final void Function(LatLng ponto, String nome, String? completo) aoEscolher;

  final LatLng? local;
  final String? descricao;
  final String dica;

  /// Erro de validação vindo do formulário.
  final String? erro;

  @override
  State<BuscaLocal> createState() => _BuscaLocalState();
}

class _BuscaLocalState extends State<BuscaLocal> {
  static const _espera = Duration(milliseconds: 450);

  final _texto = TextEditingController();
  List<Destino> _sugestoes = const [];
  Timer? _timer;
  int _consulta = 0;
  String? _erro;

  @override
  void dispose() {
    _timer?.cancel();
    _texto.dispose();
    super.dispose();
  }

  void _aoDigitar(String texto) {
    _timer?.cancel();
    _consulta++;
    if (texto.trim().length < 3) {
      setState(() => _sugestoes = const []);
      return;
    }
    _timer = Timer(_espera, () => _buscar(texto));
  }

  Future<void> _buscar(String texto) async {
    final consulta = ++_consulta;
    List<Destino> achados;
    try {
      achados = await RotasService.instance.buscarEnderecos(
        texto,
        perto: LocalizacaoService.instance.posicao.value?.ponto,
      );
    } on RotaException catch (e) {
      if (mounted && consulta == _consulta) setState(() => _erro = e.mensagem);
      return;
    }
    if (!mounted || consulta != _consulta) return;
    setState(() {
      _sugestoes = achados;
      _erro = achados.isEmpty ? 'Nenhum endereço encontrado.' : null;
    });
  }

  void _escolher(Destino d) {
    _timer?.cancel();
    _consulta++;
    FocusScope.of(context).unfocus();
    _texto.text = d.detalhe ?? d.nome;
    setState(() {
      _sugestoes = const [];
      _erro = null;
    });
    widget.aoEscolher(d.posicao, d.nome, d.detalhe);
  }

  Future<void> _usarPosicao() async {
    try {
      final p = await LocalizacaoService.instance.atual();
      if (!mounted) return;
      setState(() => _erro = null);
      widget.aoEscolher(
          p.ponto, p.deTeste ? 'Posição de teste (sem GPS)' : 'Sua posição atual', null);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível obter a sua posição.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final local = widget.local;
    final erro = _erro ?? widget.erro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _texto,
          onChanged: _aoDigitar,
          decoration: InputDecoration(
            hintText: widget.dica,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        for (final d in _sugestoes)
          ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_outlined),
            title: Text(d.nome),
            subtitle: d.detalhe == null ? null : Text(d.detalhe!),
            onTap: () => _escolher(d),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _usarPosicao,
            icon: const Icon(Icons.my_location),
            label: const Text('Usar minha posição atual'),
          ),
        ),
        if (local != null)
          Text(
            '${widget.descricao ?? 'Local escolhido'} '
            '(${formatarCoordenada(local)})',
            style: TextStyle(color: cores.onSurfaceVariant),
          ),
        if (erro != null) Text(erro, style: TextStyle(color: cores.error)),
      ],
    );
  }
}
