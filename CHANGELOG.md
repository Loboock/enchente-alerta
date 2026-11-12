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

# [10/11/2026]

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