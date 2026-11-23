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
      'Em "Meus dados" você vê o e-mail da conta, muda o nome e pede uma '
      'senha nova. "Notificações" guarda os alertas que chegaram para você.\n\n'
      '"Alertas de alagamento" liga ou desliga os alertas no Início, e '
      '"Raio dos alertas" e "Endereço padrão" definem a sua região.\n\n'
      'Seus avisos são anônimos: os outros moradores não veem quem enviou.\n\n'
      'Use "Sair" para desconectar deste aparelho.';

  static const enderecos =
      'Cadastre a sua casa (e outros lugares, se quiser) buscando a rua ou '
      'usando a posição atual.\n\n'
      'O endereço padrão é o ponto de partida do raio dos alertas: alertas '
      'ligados a áreas de risco só aparecem se a área estiver perto dele. '
      'Use o menu de cada endereço para trocar o padrão, editar ou excluir.';

  static const notificacoes =
      'Cada alerta da Defesa Civil que chegou para a sua região fica aqui. '
      'Toque para ver o alerta e marcar como lido.\n\n'
      'Notificação excluída não volta enquanto o alerta continuar ativo. '
      'Para não receber mais, desligue "Alertas de alagamento" no Perfil.';

  static const meusDados =
      'Altere o seu nome e toque em "Salvar alterações".\n\n'
      'O e-mail é o login da conta e não muda por aqui. "Alterar senha" '
      'envia um link para o seu e-mail.\n\n'
      'Seu nome nunca aparece nos avisos que você envia.';

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
      'Últimos alagamentos e vias obstruídas registrados na sua região, '
      'inclusive os que já acabaram.\n\n'
      'O selo mostra a situação: "Ativo agora", "Resolvido" (a Defesa Civil '
      'confirmou que a água baixou) ou "Expirado" (o prazo do aviso venceu). '
      'Sem internet, aparece o histórico salvo no aparelho.\n\n'
      'Serve para conhecer os pontos que costumam alagar e evitá-los em dias '
      'de chuva.';

  static const painelDefesaCivil =
      'Painel exclusivo das contas da Defesa Civil.\n\n'
      '"Denúncias" mostra os avisos que os moradores marcaram como errados: '
      'resolva o aviso, mantenha-o ou exclua se for falso.\n\n'
      '"Alertas" emite os alertas que aparecem para todos no Início e na aba '
      'Avisos. "Abrigos" cadastra os abrigos e atualiza as vagas.';

  static const denuncias =
      'Cada cartão é um aviso denunciado, com os motivos dos moradores.\n\n'
      '"Resolver" tira o aviso do mapa (a água baixou) e guarda no histórico. '
      '"Manter" apaga as denúncias e o aviso continua. "Excluir" apaga o '
      'aviso falso ou abusivo.\n\n'
      'Os moradores que denunciaram não são identificados aqui.';

  static const alertasDefesaCivil =
      'Alertas emitidos pela Defesa Civil. Os ativos aparecem para todos no '
      'Início e na aba Avisos, do mais grave ao mais leve.\n\n'
      '"Encerrar" tira o alerta da tela dos moradores antes do prazo. '
      'Alertas encerrados ficam na lista até serem excluídos.';

  static const formularioAlerta =
      'Escreva um título curto e direto (ex.: "Chuva forte nas próximas 3 '
      'horas"). A descrição é opcional.\n\n'
      'O nível define a cor do alerta. A validade conta a partir de agora; '
      'depois dela o alerta some sozinho.';

  static const abrigosDefesaCivil =
      'Abrigos cadastrados que os moradores veem em "Abrigos próximos" e nas '
      'rotas de fuga.\n\n'
      'Use − e + para atualizar as vagas na hora. Um abrigo desativado some '
      'da lista dos moradores sem ser excluído.';

  static const formularioAbrigo =
      'Informe nome, bairro, capacidade e vagas livres (no máximo a '
      'capacidade).\n\n'
      'Para o local, busque o endereço e escolha uma sugestão, ou use a sua '
      'posição atual se estiver no abrigo.';

  static const mapaOffline =
      '"Salvar mapa da região" guarda no aparelho o mapa de cerca de 3 km '
      'em volta de onde você está. Faça isso em casa, com Wi-Fi, antes da '
      'chuva.\n\n'
      'Sem internet, o app mostra a faixa "Sem internet" e usa o mapa, os '
      'avisos, os abrigos e o histórico salvos. Criar aviso e calcular rota '
      'nova precisam de conexão.';

  static const guia =
      'O que fazer antes, durante e depois de uma enchente, e o que levar se '
      'precisar sair de casa.\n\n'
      'No fim da tela ficam os telefones de emergência: Defesa Civil 199, '
      'SAMU 192 e Bombeiros 193.';
}
