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

### Alterado
- Diagrama de casos de uso refeito para a Unidade II: atores Visitante (sem conta), Usuário cadastrado e Defesa Civil com herança, casos de login, criação de conta e recuperação de senha, controle de acesso da Defesa Civil e correções de UML (docs/diagrama-casos-de-uso.png, fonte em docs/fontes/).
- Diagrama de classes atualizado: entram Ocorrencia, TipoOcorrencia, Denuncia, Abrigo, RotaFuga, PacoteOffline e PerfilUsuario; saem Mapa, EstacaoMonitoramento e OcorrenciaHistorica; NivelAlerta vira Gravidade com 3 níveis (docs/diagrama-de-classes.md).

- Registro de uso de IA renomeado para docs/uso-de-ia.md, como pede o enunciado, e reorganizado em: ferramentas, prompts mais eficientes, erros gerados pela IA e soluções, justificativa das bibliotecas e validação.

### Removido
- Diagrama de casos de uso antigo (Diagrama-de-casos-de-uso.drawio.png) e diagrama de classes antigo em HTML (docs/diagrama_de_classes), substituídos pelas versões acima.
