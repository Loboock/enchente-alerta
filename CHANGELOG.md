# Changelog

## [01/09/2026]

### Adicionado
- Criação do repositório do projeto EnchenteAlerta.
- README.md com informações do projeto, integrantes, turma e responsabilidades.
- Análise inicial do estudo de caso (docs/estudo-de-caso.md).

## [08/09/2026]

### Adicionado
- Realizada a pesquisa sobre o problema e o publico do estudo de caso(docs/pesquisa.md).
- Criado as personas e selecionada a persona prioritária(docs/persona.md).
- Criado as benchmarks analisando 3 soluções existentes relacionadas ao problema do projeto(docs/benchmark.md).

  ## [15/09/2026]

### Adicionado
- requisitos funcionais e não funcionais adicionado(docs/requisitos.md)
- funcionalidades adicionadas(docs/requisitos.md)
- adicionados os CRUDs(docs/requisitos.mds)
- adicionado priorização(docs/requisitos.md)

# [22/09/2026]

### Adicionado
- Prototipo de baixa fidelidade adicionado(docs/prototipoBaixaFidelidade.pdf)

# [29/09/2026]

### Adicionado
- Prototipo de alta fidelidade adicionado(docs/prototipoAltaFidelidade.pdf)

# [05/10/2026]

### Adicionado
- Adicionado apresentação final unidade 1(docs/apresentacaoFinalUnidade1.pdf)

# [03/11/2026]

### Adicionado
- Diagrama de classes em HTML
- Diagrama de casos de uso em PNG

# [09/11/2026]

### Adicionado
- Projeto Firebase "enchente-alerta" criado no plano gratuito (Spark), com Authentication por e-mail/senha e Cloud Firestore em southamerica-east1 (São Paulo), iniciado em modo de produção.
- Projeto Flutter criado na raiz do repositório (pacote br.unit.enchentealerta.enchente_alerta, plataforma Android) e conectado ao Firebase com o FlutterFire CLI (lib/firebase_options.dart e android/app/google-services.json).
- Pacotes firebase_core, firebase_auth e cloud_firestore adicionados ao pubspec.yaml.
- Ambiente validado: app de exemplo compilado e executado no emulador Pixel 8 (Android 17). Foi necessário instalar o NDK 28.2.13676358 pelo SDK Manager do Android Studio, porque o Gradle não conseguiu instalá-lo sozinho.
- Modelagem do banco de dados no Firestore: estrutura de coleções e documentos, mapeamento das classes Dart para o Firestore (fromFirestore/toFirestore), resumo de tipos e regras de segurança por perfil de acesso (docs/modelagem-firestore.md).

- Arquivo CLAUDE.md com o contexto do projeto, regras de trabalho e decisões tomadas, para uso com o Claude Code (registro de uso de IA).
- Tema visual do app (lib/theme/app_theme.dart) com as cores do protótipo de alta fidelidade: azul-escuro (#1A4D8F), azul-marinho (#172447) e laranja de alerta (#FF8D28); textos maiores e botões com no mínimo 48 dp (RNF02), modo noturno que segue o aparelho (RNF03) e alto contraste (RNF10).
- Tela inicial provisória, que será substituída pela navegação com barra inferior.
- Registro de uso de IA: Claude Code na tabela de ferramentas e o prompt usado para gerar o tema, com a decisão sobre a cor de destaque (docs/uso-de-ia.md).

### Alterado
- lib/main.dart: o Firebase passa a ser inicializado antes de abrir o app; o exemplo do contador foi removido e o teste de widget (test/widget_test.dart) foi ajustado para a nova tela.
- Diagrama de casos de uso refeito para a Unidade II: atores Visitante (sem conta), Usuário cadastrado e Defesa Civil com herança, casos de login, criação de conta e recuperação de senha, controle de acesso da Defesa Civil e correções de UML (docs/diagrama-casos-de-uso.png, fonte em docs/fontes/).
- Diagrama de classes atualizado: entram Ocorrencia, TipoOcorrencia, Denuncia, Abrigo, RotaFuga, PacoteOffline e PerfilUsuario; saem Mapa, EstacaoMonitoramento e OcorrenciaHistorica; NivelAlerta vira Gravidade com 3 níveis (docs/diagrama-de-classes.md).

- Registro de uso de IA renomeado para docs/uso-de-ia.md, como pede o enunciado, e reorganizado em: ferramentas, prompts mais eficientes, erros gerados pela IA e soluções, justificativa das bibliotecas e validação.

### Removido
- Diagrama de casos de uso antigo (Diagrama-de-casos-de-uso.drawio.png) e diagrama de classes antigo em HTML (docs/diagrama_de_classes), substituídos pelas versões acima.

# [10/11/2026]

### Adicionado
- Tela Início igual ao protótipo de alta fidelidade (lib/screens/inicio/tela_inicio.dart): cabeçalho azul com botão de ajuda, mapa com a área de risco em destaque (círculo vermelho), barra de atalhos de locais (Hosp. Universitário, Escola Exemplo, Farolândia) e botões Abrigo e Rota de fuga.
- Navegação com barra inferior (Início, Avisos, Histórico, Perfil, Guia) em lib/screens/tela_principal.dart e lib/widgets/barra_navegacao_inferior.dart; as abas ainda sem tela usam uma tela provisória "Em construção".
- Pacotes flutter_map e latlong2 no pubspec.yaml (mapa do OpenStreetMap) e permissão INTERNET no AndroidManifest.xml.
- Branch develop para juntar as tarefas do grupo por Pull Request, revisados e mesclados pelo Vinicius; guia do fluxo de trabalho em CONTRIBUTING.md (branches feature/, PR para a develop, padrão de commits).
- Classes de domínio em lib/models/ (Usuario, PreferenciaNotificacao, Endereco, Notificacao, Ocorrencia, Denuncia, Alerta, AreaRisco, Abrigo, RotaFuga, GuiaOrientacao) e as 7 enumerações, com fromFirestore/toFirestore conforme docs/modelagem-firestore.md. PacoteOffline fica para a tarefa do modo offline, porque não vai para o Firestore.
- Testes do mapeamento Dart <-> Firestore (test/models_test.dart).

### Alterado
- lib/main.dart: a tela inicial provisória foi substituída pela TelaPrincipal.
- test/widget_test.dart: testes ajustados para a tela Início e a troca de abas.
- docs/modelagem-firestore.md: exemplo de código atualizado para as classes reais (enums com campo codigo e coordenadas em LatLng).
- docs/uso-de-ia.md: prompt das classes de domínio e erro da IA nas enumerações.

### Removido
- Tela inicial provisória (TelaInicialProvisoria) do main.dart.
- Telas de Login, Cadastro, Recuperar senha e Perfil enviadas direto na develop, sem Pull Request, retiradas da develop porque os imports apontavam para arquivos inexistentes (102 erros no flutter analyze). O trabalho foi guardado na branch feature/telas-conta para ser corrigido e voltar por Pull Request.

# [12/11/2026]

### Adicionado
- Tela Rota de fuga (lib/screens/rota/tela_rota_fuga.dart), igual ao protótipo 02: mapa com o traçado em vermelho, marcadores do destino e do usuário e painel com distância, tempo a pé e de carro, risco e botão Iniciar navegação.
- Tela Abrigos próximos (lib/screens/abrigos/tela_abrigos_proximos.dart), igual ao protótipo 03: lista ordenada por distância; tocar em um abrigo abre a rota até ele.
- Tela de escolha de destino (lib/screens/rota/tela_escolher_destino.dart), que não existe no protótipo: campo de busca por endereço sem acento/maiúscula, locais salvos e sugestões.
- Dados provisórios em lib/data/dados_provisorios.dart (abrigos, locais e rota de mentira), que serão trocados pelo Firestore. As telas usam os models Abrigo, RotaFuga e Gravidade já existentes.
- Widgets compartilhados: AppBarTela, CartaoLocal, ScaffoldComAbas e AtribuicaoMapa (lib/widgets/); formatação de distância, busca sem acento, cor da gravidade e texto de lotação (lib/utils/); classe Destino (lib/models/destino.dart).
- Testes de widget para o fluxo Abrigo → rota, Rota de fuga → destino → rota, busca de destino e volta às abas pela barra inferior.

### Alterado
- Tela Início: o botão Abrigo abre a lista de abrigos e o botão Rota de fuga abre a escolha de destino; o cabeçalho passou a usar o widget AppBarTela.
- TelaPrincipal passou a ler a aba atual de lib/navegacao.dart, para que as telas abertas por cima da principal consigam trocar de aba.
- CHANGELOG: data da entrada das telas de rota e abrigos corrigida de 10/11 para 12/11, dia em que foram enviadas.

# [15/11/2026]

### Adicionado
- Login, Cadastro e Recuperar senha com o Firebase Auth (lib/services/auth_service.dart): entrar, criar conta, enviar e-mail de recuperação de senha e sair, com mensagens de erro em português (e-mail inválido, senha fraca, e-mail já cadastrado, sem internet, muitas tentativas).
- Ao criar conta, o app grava `usuarios/{uid}` com a classe Usuario (perfil MORADOR). Enquanto as regras do Firestore não liberam a gravação, a conta é criada só no Auth, sem travar o cadastro.
- Aba Perfil: mostra o login para quem não está logado e os dados da conta (nome, notificações, sair) para quem está.
- Testes de widget: o Visitante abre a aba Perfil sem conta e o login valida os campos antes de chamar o Firebase (test/widget_test.dart).
- Regras de segurança do Firestore (firestore.rules) com controle de acesso por perfil: o Visitante só lê dados públicos; o Morador registra ocorrências, exclui as próprias, denuncia avisos e cuida só dos próprios dados; a Defesa Civil também gerencia abrigos, rotas, alertas, áreas de risco e guias. Ninguém vira Defesa Civil pelo app.
- Anonimato do autor (RNF07) garantido pelas regras: a ocorrência só é aceita junto com o seu autor em autoresOcorrencias, na mesma gravação, e só o autor e a Defesa Civil veem quem registrou.
- Validação dos dados nas regras: só os campos da modelagem, enumerações com códigos válidos, tamanho máximo dos textos, nível da água de 0 a 500 cm, expiração depois da criação e vagas do abrigo até a capacidade.
- 23 testes das regras no emulador do Firestore (firestore-testes/), com instruções para rodar.
- firebase.json e .firebaserc configurados para aplicar as regras com `firebase deploy --only firestore:rules`.

### Alterado
- Telas de conta reorganizadas: lib/screens/conta/ (tela_login, tela_registro, tela_reset_senha, tela_perfil), lib/services/auth_service.dart e lib/widgets/widgets_conta.dart, com os imports corrigidos.
- As telas de conta usam as cores do tema do app (Theme.of(context).colorScheme e AppColors), funcionando também no modo escuro, e a mesma barra do topo das outras abas.
- Recuperar senha agora envia o e-mail do Firebase com o link para criar a nova senha, em vez de trocar a senha direto no app.
- lib/screens/tela_principal.dart: a aba Perfil deixa de ser "Em construção".
- Branch feature/telas-conta atualizada com a develop (telas de rota e abrigos): conflitos em tela_principal.dart, widget_test.dart e CHANGELOG resolvidos mantendo as duas partes; o teste de volta às abas pela barra inferior passou a esperar o login na aba Perfil.
- AuthService: o documento usuarios/{uid} usa o e-mail como o Firebase guarda (minúsculas), exigido pelas regras, e é criado no login quando a conta foi feita antes das regras.
- docs/modelagem-firestore.md: seção de regras de segurança atualizada com a tabela final, o funcionamento do anonimato e das validações e um exemplo de gravação da ocorrência com o autor.
- docs/uso-de-ia.md: prompt das regras do Firestore.

### Removido
- lib/screens/main.dart (o app já tem o lib/main.dart, que inicializa o Firebase e abre sem exigir login).
- lib/screens/theme.dart (paleta própria, substituída pelas cores do tema do app).
- lib/screens/placeholder.dart e a barra inferior própria das telas de conta (AppShell), que duplicava a navegação do app e bloqueava o Visitante.
- Login falso em memória (teste@gmail.com).

# [16/11/2026]

### Adicionado
- Localização real do usuário com o pacote geolocator (lib/services/localizacao_service.dart): pede a permissão, acompanha o GPS e, sem GPS, usa a posição de teste da Farolândia com aviso na tela.
- Rotas de fuga reais com o OpenRouteService (lib/services/rotas_service.dart), de carro ou a pé, que desviam das áreas da Defesa Civil (`areasRisco`) e dos avisos de moradores com 2 ou mais confirmações (`options.avoid_polygons`).
- Alagamentos em tempo real no mapa (lib/services/perigos_service.dart e lib/models/perigo.dart): vermelho quando a rota desvia, laranja quando o aviso ainda não foi confirmado.
- Botão Reportar no mapa, como no Waze (lib/widgets/mapa/folha_reportar.dart): cria a ocorrência na posição atual, com o autor em `autoresOcorrencias` (RNF07). Exige login.
- Detalhes do aviso ao tocar no mapa, com "Ainda está aí" (confirmação, uma por pessoa) e "Não está mais" (denúncia com motivo AGUA_BAIXOU) (lib/widgets/mapa/folha_perigo.dart).
- Tela de navegação curva a curva (lib/screens/rota/tela_navegacao.dart): próxima manobra, mapa que segue e gira com o usuário, recálculo ao sair da rota ou quando um alagamento é confirmado à frente.
- Busca de endereços reais na escolha de destino.
- Campo `confirmacoes` em Ocorrencia e subcoleção `ocorrencias/{id}/confirmacoes/{uid}` (docs/modelagem-firestore.md, com as regras de segurança atualizadas).
- Configuração da chave do OpenRouteService por `--dart-define-from-file=config.json` (lib/config.dart, docs/rotas-e-mapa.md); `config.json` no .gitignore.
- Permissões de localização no AndroidManifest.xml.
- Testes: rotas e perigos com resposta falsa do OpenRouteService (test/rotas_test.dart), GPS e rotas falsos nos testes de widget (test/fakes.dart), navegação e reportar sem login (test/widget_test.dart).

### Alterado
- Tela Início: mapa ao vivo, centrado no usuário, com botões de recentralizar e reportar.
- Tela Rota de fuga: rota calculada na hora, com tempo, distância, hora de chegada, escolha carro/a pé e avisos de alagamento evitado ou sem confirmação.
- Telas Abrigos próximos e Escolher destino: distâncias medidas a partir da posição real.
- Tela de escolha de destino da Rota de fuga: agora a pessoa digita um endereço real, escolhe uma sugestão e o app calcula a rota que desvia dos alagamentos, no lugar da lista de locais fixos.
- Fundo do mapa: OpenStreetMap padrão (escurecido no modo noturno) ou, com a chave opcional `CARTO_API_KEY`, CARTO Voyager e Dark Matter.

### Removido
- Rota de mentira (`rotaProvisoria`) e locais fixos (`locaisSalvos`, `sugestoes`) de lib/data/dados_provisorios.dart.
- lib/widgets/atribuicao_mapa.dart (o crédito do mapa agora fica dentro de lib/widgets/mapa/mapa_enchente.dart).


# [17/11/2026]

### Adicionado
- Regras das confirmações de aviso em firestore.rules: o aviso novo começa com 1 confirmação (a do autor, gravada na mesma operação); "Ainda está aí" soma exatamente 1 por pessoa e renova o prazo para no máximo 5 h; cada pessoa só lê e cria a própria marca em `ocorrencias/{id}/confirmacoes/{uid}`. Todas as validações anteriores foram mantidas.
- 7 testes das confirmações no emulador do Firestore (firestore-testes/regras.test.js, agora com 30 testes).

### Alterado
- Resolvidas as marcas de conflito do `git stash` que foram no commit de 16/11 (.gitignore, docs/modelagem-firestore.md, docs/uso-de-ia.md), mantendo o conteúdo dos dois lados.
- docs/modelagem-firestore.md: seção 5 com a linha das confirmações na tabela de acesso e a explicação da regra; o esboço antigo de regras saiu (as regras valem pelo firestore.rules).
- docs/uso-de-ia.md: prompt das rotas renumerado para 9 e erros para 12 a 14; adicionado o erro 15 (confirmações sem regra no Firestore).
- docs/rotas-e-mapa.md: as regras ficam no firestore.rules e são publicadas pelo Vinicius após o merge.
