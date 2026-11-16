import 'package:flutter/material.dart';

import '../../data/dados_provisorios.dart';
import '../../models/destino.dart';
import '../../utils/formatacao.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/cartao_local.dart';
import '../../widgets/scaffold_com_abas.dart';
import 'tela_rota_fuga.dart';

/// Tela para escolher o endereço de destino antes de ver a rota de fuga.
/// Não existe no protótipo: segue o mesmo visual das telas 02 e 03.
class TelaEscolherDestino extends StatefulWidget {
  const TelaEscolherDestino({super.key});

  @override
  State<TelaEscolherDestino> createState() => _TelaEscolherDestinoState();
}

class _TelaEscolherDestinoState extends State<TelaEscolherDestino> {
  final _controlador = TextEditingController();
  String _busca = '';

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _aoDigitar(String texto) => setState(() => _busca = texto);

  void _limpar() {
    _controlador.clear();
    setState(() => _busca = '');
  }

  Widget _cartao(Destino destino, String detalhe, IconData icone) {
    return CartaoLocal(
      titulo: destino.nome,
      subtitulo: detalhe,
      icone: icone,
      distancia: formatarDistancia(
        metrosEntre(usuarioProvisorio, destino.posicao),
      ),
      aoTocar: () => abrirRotaFuga(context, destino),
    );
  }

  Widget _secao(String titulo) {
    final cores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: cores.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Lista mostrada quando ainda não há texto digitado.
  List<Widget> _listaInicial() {
    return [
      _secao('Locais salvos'),
      for (final local in locaisSalvos)
        _cartao(local, 'Local salvo', Icons.place_outlined),
      _secao('Sugestões'),
      for (final local in sugestoes)
        _cartao(local, 'Endereço', Icons.place_outlined),
    ];
  }

  /// Lista filtrada pelo texto digitado (ignora acento e maiúscula).
  List<Widget> _resultados() {
    final consulta = normalizarTexto(_busca);
    bool combina(String texto) => normalizarTexto(texto).contains(consulta);

    final itens = <Widget>[
      for (final local in [...locaisSalvos, ...sugestoes])
        if (combina(local.nome))
          _cartao(local, 'Endereço', Icons.place_outlined),
      for (final abrigo in abrigosPorDistancia())
        if (combina('${abrigo.nome} ${abrigo.bairro}'))
          _cartao(
            abrigo.comoDestino,
            'Abrigo · ${abrigo.bairro}',
            Icons.home_outlined,
          ),
    ];

    if (itens.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Center(
            child: Text(
              'Nenhum local encontrado',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }
    return [_secao('Resultados'), ...itens];
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final digitando = _busca.trim().isNotEmpty;

    return ScaffoldComAbas(
      appBar: const AppBarTela(
        titulo: 'Rota de fuga',
        subtitulo: 'Escolha para onde ir',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: TextField(
              controller: _controlador,
              onChanged: _aoDigitar,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Digite um endereço ou local',
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: digitando ? _resultados() : _listaInicial(),
            ),
          ),
        ],
      ),
    );
  }
}
