import 'package:flutter/material.dart';

import '../navegacao.dart';
import '../services/auth_service.dart';
import '../widgets/barra_navegacao_inferior.dart';
import 'avisos/tela_avisos.dart';
import 'conta/tela_perfil.dart';
import 'guia/tela_guia.dart';
import 'historico/tela_historico.dart';
import 'inicio/tela_inicio.dart';

/// Estrutura principal do app: telas das cinco abas + barra inferior.
class TelaPrincipal extends StatelessWidget {
  const TelaPrincipal({super.key});

  static const _telas = <Widget>[
    TelaInicio(),
    TelaAvisos(),
    TelaHistorico(),
    // Sem conta mostra o login; logado mostra os dados da conta.
    ProfileScreen(),
    TelaGuia(),
  ];

  @override
  Widget build(BuildContext context) {
    // A aba escolhida fica em `abaAtual` para que as telas abertas por cima
    // (abrigos, rota) também consigam trocar de aba.
    // Também redesenha quando a conta muda (a Defesa Civil vê "Painel").
    return ListenableBuilder(
      listenable: Listenable.merge([abaAtual, AuthService.instance]),
      builder: (context, _) => Scaffold(
        // IndexedStack mantém o mapa vivo ao trocar de aba (não recarrega).
        body: IndexedStack(index: abaAtual.value, children: _telas),
        bottomNavigationBar: BarraNavegacaoInferior(
          itens: itensNavegacao,
          indiceAtual: abaAtual.value,
          aoSelecionar: (i) => abaAtual.value = i,
        ),
      ),
    );
  }
}
