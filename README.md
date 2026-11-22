# EnchenteAlerta

Aplicativo mobile de prevenção de enchentes e saúde comunitária, voltado para moradores de áreas de risco (várzeas e encostas), Defesa Civil, bombeiros e líderes comunitários. O app oferece mapa de pontos de alagamento, alertas de chuvas fortes, guia de preparação para temporais e rotas de fuga com lista de abrigos, com foco em uso offline e em situações de emergência.

## Integrantes

- Vinicius Reis — Desenvolvimento
- Bernardo Gonçalves do Carmo — Desenvolvimento
- Pedro Brid do Carmo Fraife — **Líder do grupo**
- Christian Gonçalves — Desenvolvimento

## Turma / Disciplina

Programação para Dispositivos Móveis — Profa. Layse Santos Souza (Unit, Ciência da Computação)

## Tecnologias

- Dart e Flutter (Android)
- Firebase Authentication (e-mail e senha) e Cloud Firestore, no plano gratuito (Spark)
- `flutter_map` com OpenStreetMap, `geolocator` e OpenRouteService (rotas que desviam dos alagamentos)

## Como rodar

1. Instale o Flutter e o Android Studio (emulador Android).
2. Na raiz do projeto: `flutter pub get`.
3. Para as rotas de fuga, crie o arquivo `config.json` com a chave gratuita do OpenRouteService (passo a passo em [`docs/rotas-e-mapa.md`](docs/rotas-e-mapa.md)). Sem a chave, o app abre normalmente, mas a tela de rota avisa que falta a chave.
4. Rode com `flutter run --dart-define-from-file=config.json`. No emulador, acrescente `--dart-define=LOCALIZACAO_TESTE=true` para usar uma posição em Aracaju.

Testes: `flutter test` (app) e `npm test` dentro de [`firestore-testes/`](firestore-testes/) (regras do Firestore). O fluxo de branches e PRs está em [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Documentação

| Arquivo | Conteúdo |
|---|---|
| [`docs/requisitos.md`](docs/requisitos.md) | Funcionalidades, requisitos funcionais e não funcionais, CRUDs |
| [`docs/diagrama-casos-de-uso.png`](docs/diagrama-casos-de-uso.png) | Casos de uso da Unidade II |
| [`docs/diagrama-de-classes.md`](docs/diagrama-de-classes.md) | Classes de domínio |
| [`docs/modelagem-firestore.md`](docs/modelagem-firestore.md) | Coleções do Firestore, mapeamento Dart e regras de segurança |
| [`docs/rotas-e-mapa.md`](docs/rotas-e-mapa.md) | Mapa, rotas de fuga e avisos de alagamento |
| [`docs/fluxo-navegacao.md`](docs/fluxo-navegacao.md) | Fluxo de navegação real do app |
| [`docs/planejamento.md`](docs/planejamento.md) | Escopo, EAP simplificada e planejamento em sprints |
| [`docs/uso-de-ia.md`](docs/uso-de-ia.md) | Registro do uso de IA |
| [`CHANGELOG.md`](CHANGELOG.md) | Histórico de mudanças |

## Responsabilidades — Unidade I

 **Vinicius Reis:** 
- fez a benchmark em colaboração com Bernardo.
- criou o github e participou da criação do documento.
- fez os CRUDs.
- participou dos prototipos, tanto o de alta quanto o de baixa.
- Ajudou na criação da apresentação.

 **Bernardo Gonçalves do Carmo:** 
- fez a benchmark em colaboração com Vinicius Reis.
- participou da criação do documento.
- fez as funcionalidades.
- participou dos prototipos, tanto o de alta quanto o de baixa.
- Ajudou na criação da apresentação.
- fez os outros atores e as cartinhas de fora no diagrama de casos
  
 **Pedro Brid do Carmo Fraife:**(Líder)
- organização do repositório, fez as personas.
- participou da criação do documento.
- fez os requisitos funcionais e não funcionais.
- participou dos prototipos, tanto o de alta quanto o de baixa.
- Ajudou na criação da apresentação.
- fez o ator principal no diagrama de casos de uso
  
 **Christian Gonçalves:** 
- fez as pesquisas.
- participou da criação do documento.
- fez as priorização.
- participou dos prototipos, tanto o de alta quanto o de baixa.
- Ajudou na criação da apresentação.
- fez o diagrama de classes

## Responsabilidades — Unidade II

Cada integrante faz commits com a própria conta, em uma branch `feature/` com PR para a `develop`. O Vinicius revisa e mescla os PRs.

### Antes das sprints (03 a 09/11)

- **Pedro Brid do Carmo Fraife:** diagrama de casos de uso inicial da Unidade II e registro das contribuições no README e no CHANGELOG.
- **Christian Gonçalves:** diagrama de classes (versões em HTML e PDF) e o prompt usado para gerá-lo.
- **Vinicius Reis:** atualização dos diagramas de casos de uso e de classes para as regras da Unidade II; modelagem do Firestore com o mapeamento das classes Dart; criação do projeto Flutter e do projeto Firebase; organização do `docs/uso-de-ia.md`.

### Sprint 1 (10 a 16/11)

**Vinicius Reis**
- Inicialização do Firebase no app e tema claro/escuro com as cores do protótipo.
- Classes de domínio em `lib/models/` com `fromFirestore`/`toFirestore`.
- Regras de segurança do Firestore: controle de acesso por perfil (Visitante, Morador, Defesa Civil), anonimato do autor da ocorrência (RNF07), validação dos campos, confirmações de aviso e uma denúncia por pessoa, com testes no emulador (`firestore-testes/`).
- Telas Avisos, Criar aviso e Reportar aviso, ligadas ao Firestore.
- Fluxo de branches (`CONTRIBUTING.md`), revisão e merge dos PRs, resolução de conflitos nas branches dos colegas e correções encontradas nos testes (cadastro gravando o usuário duas vezes, aviso escondido sob o ponto do usuário).

**Pedro Brid do Carmo Fraife** (líder)
- Navegação com a barra inferior e tela Início com o mapa.
- Telas Rota de fuga e Abrigos próximos.
- Localização real do usuário (GPS), rotas de fuga pelo OpenRouteService que desviam dos alagamentos, navegação curva a curva e busca de endereços.
- Botão Reportar no mapa, com confirmação ("Ainda está aí") e negação ("Não está mais") dos avisos; a rota só desvia de um aviso com 2 confirmações.
- Documentação do mapa e das rotas (`docs/rotas-e-mapa.md`).

**Christian Gonçalves**
- Telas Entrar, Cadastrar, Recuperar senha e Perfil.
- Serviço de autenticação (`lib/services/auth_service.dart`) com Firebase Auth, mensagens de erro em português e acesso livre para o Visitante.

**Bernardo Gonçalves do Carmo**
- Telas Histórico, Guia de segurança (com os telefones de emergência) e Ajuda.
- Botão de ajuda do cabeçalho ligado à tela Ajuda e testes de widget das três telas.

### Sprint 2 (17 a 23/11)

**Vinicius Reis**
- Perfil da Defesa Civil: aba "Painel" com revisão de denúncias (resolver, manter ou excluir avisos), CRUD de alertas e CRUD de abrigos com ajuste de vagas.
- Faixa de alertas da Defesa Civil no Início e na aba Avisos; abrigos lidos do Firestore.
- Regras do Firestore para o painel (lista de denúncias e validação de alertas e abrigos), com testes no emulador.

A definir com o grupo: Histórico lendo do Firestore, uso offline e telas do Perfil (Meus dados, Notificações e Endereço padrão).
