import 'package:flutter/material.dart';

import '../screens/ajuda/tela_ajuda.dart';
import '../theme/app_theme.dart';

/// Botão "i" do canto do cabeçalho.
///
/// Com [texto], mostra a ajuda própria da tela (ver [TextosAjuda]) e um
/// atalho para a tela Ajuda completa. Sem [texto] (tela Início), abre
/// direto a tela Ajuda. [ativa] = está na própria Ajuda: fica laranja e
/// não faz nada.
class BotaoAjuda extends StatelessWidget {
  const BotaoAjuda({super.key, this.texto, this.ativa = false});

  final String? texto;
  final bool ativa;

  @override
  Widget build(BuildContext context) {
    final texto = this.texto;
    return IconButton(
      tooltip: 'Ajuda',
      iconSize: 40,
      padding: const EdgeInsets.all(4),
      color: ativa ? AppColors.alerta : Colors.white,
      disabledColor: AppColors.alerta,
      icon: const Icon(Icons.info_outline),
      onPressed: ativa
          ? null
          : texto == null
              ? () => abrirAjuda(context)
              : () => mostrarAjuda(context, texto),
    );
  }
}

/// Caixa com a ajuda da tela e o atalho para a tela Ajuda completa.
void mostrarAjuda(BuildContext context, String texto) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajuda'),
        content: SingleChildScrollView(child: Text(texto)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              abrirAjuda(context);
            },
            child: const Text('Ver ajuda completa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );

/// Texto de ajuda de cada tela, num lugar só para facilitar a revisão.
abstract final class TextosAjuda {
  static const login =
      'O Enchente Alerta envia avisos de alagamento da sua região em tempo real.\n\n'
      'Você pode usar o app sem conta. A conta serve para criar avisos e '
      'configurar alertas.\n\n'
      'Problemas com acesso? Use "Esqueceu a senha?" na tela de login.';

  static const cadastro =
      'Crie sua conta com e-mail e uma senha de pelo menos 8 caracteres.\n\n'
      'Com a conta você pode avisar alagamentos, confirmar avisos de outros '
      'moradores e configurar alertas.\n\n'
      'Seu nome nunca aparece nos avisos que você enviar.';

  static const recuperarSenha =
      'Informe o e-mail da sua conta e enviaremos um link para criar uma '
      'nova senha.\n\n'
      'Não recebeu? Confira a caixa de spam ou tente de novo em alguns minutos.';

  static const perfil =
      'Aqui ficam os dados da sua conta: em "Meus dados" você muda o nome e '
      'em "Notificações" liga ou desliga os alertas de alagamento.\n\n'
      'Seus avisos são anônimos: os outros moradores não veem quem enviou.\n\n'
      'Use "Sair" para desconectar deste aparelho.';

  static const abrigos =
      'Lista dos abrigos do mais perto para o mais longe, com a situação de '
      'cada um.\n\n'
      'Toque em um abrigo para ver a rota mais segura até ele, desviando das '
      'áreas alagadas.';

  static const escolherDestino =
      'Em cima fica a partida e embaixo o destino. Com a localização ativa, '
      'a partida já vem como "Sua localização"; toque nela para sair de '
      'outro endereço.\n\n'
      'Digite o destino e escolha uma das sugestões. O caminho desvia dos '
      'alagamentos avisados no mapa.\n\n'
      'Funciona sem conta e sem liberar a localização.';

  static const rotaFuga =
      'Esta é a rota de menor risco até o destino, desviando dos alagamentos '
      'e das áreas de risco.\n\n'
      'Escolha carro ou a pé e veja tempo, distância e hora de chegada. '
      '"Cancelar" volta para trocar a partida ou o destino.\n\n'
      '"Iniciar navegação" guia você curva a curva e recalcula se surgir um '
      'alagamento no caminho. Sem GPS ou saindo de outro endereço, ela '
      'mostra uma manobra por vez e você avança com "Próxima".';

  static const avisos =
      'Lista dos alagamentos ativos agora, com gravidade, nível da água e '
      'há quanto tempo foram avisados.\n\n'
      'Use "Criar aviso" para avisar a vizinhança e "Reportar" se um aviso '
      'estiver errado. Os avisos que você criou têm o botão "Excluir".\n\n'
      'Criar, reportar e excluir pedem uma conta.';

  static const criarAviso =
      'Informe o endereço do alagamento, a gravidade e o nível da água em '
      'centímetros. A descrição é opcional.\n\n'
      'O aviso aparece na hora no mapa e na lista, e as rotas de fuga passam '
      'a desviar dele. Seu nome não aparece no aviso.';

  static const reportarAviso =
      'Escolha o que está errado no aviso e, se quiser, explique nos '
      'detalhes.\n\n'
      'A denúncia vai para a Defesa Civil analisar. Cada pessoa reporta um '
      'aviso uma vez só.';

  static const historico =
      'Últimos alagamentos registrados na sua região, inclusive os que já '
      'acabaram.\n\n'
      'Serve para conhecer os pontos que costumam alagar e evitá-los em dias '
      'de chuva.';

  static const guia =
      'O que fazer antes, durante e depois de uma enchente, e o que levar se '
      'precisar sair de casa.\n\n'
      'No fim da tela ficam os telefones de emergência: Defesa Civil 199, '
      'SAMU 192 e Bombeiros 193.';
}
