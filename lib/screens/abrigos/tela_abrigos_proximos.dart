import 'package:flutter/material.dart';

import '../../data/dados_provisorios.dart';
import '../../models/destino.dart';
import '../../utils/formatacao.dart';
import '../../utils/situacao_abrigo.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/cartao_local.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../rota/tela_rota_fuga.dart';

/// Tela "03 Abrigos próximos" do protótipo: lista dos abrigos do mais perto
/// para o mais longe. Tocar em um abrigo abre a rota de fuga até ele.
class TelaAbrigosProximos extends StatelessWidget {
  const TelaAbrigosProximos({super.key});

  @override
  Widget build(BuildContext context) {
    final lista = abrigosPorDistancia();

    return ScaffoldComAbas(
      appBar: const AppBarTela(
        titulo: 'Abrigos próximos',
        subtitulo: 'Ordenado por distância',
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: lista.length,
        itemBuilder: (context, i) {
          final abrigo = lista[i];
          return CartaoLocal(
            titulo: abrigo.nome,
            subtitulo: '${abrigo.bairro} · ${abrigo.situacao}',
            icone: Icons.home_outlined,
            distancia: formatarDistancia(
              abrigo.distanciaAte(usuarioProvisorio),
            ),
            aoTocar: () => abrirRotaFuga(context, abrigo.comoDestino),
          );
        },
      ),
    );
  }
}
