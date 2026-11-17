# Registro de Uso de IA — EnchenteAlerta

O uso de Inteligência Artificial Generativa (IAGen) é permitido na disciplina como ferramenta de apoio, desde que documentado e compreendido pelo grupo. Este arquivo registra:

1. [Ferramentas utilizadas](#1-ferramentas-utilizadas)
2. [Prompts mais eficientes](#2-prompts-mais-eficientes)
3. [Erros gerados pela IA e como o grupo resolveu](#3-erros-gerados-pela-ia-e-como-o-grupo-resolveu)
4. [Justificativa das bibliotecas escolhidas](#4-justificativa-das-bibliotecas-escolhidas)
5. [Como o grupo valida o que a IA produz](#5-como-o-grupo-valida-o-que-a-ia-produz)

Commits feitos com apoio de IA trazem a linha `Co-Authored-By: Claude` na mensagem, para que fique rastreável no histórico do repositório.

---

## 1. Ferramentas utilizadas

| Ferramenta | Uso no projeto |
|---|---|
| Claude (Anthropic) | Revisão e geração dos diagramas de casos de uso e de classes, análise dos requisitos frente ao enunciado da Unidade II, organização da documentação do repositório. |
| Claude Code (Anthropic) | Geração de código Flutter no repositório (inicialização do Firebase e tema do app), seguindo o contexto e as regras do `CLAUDE.md`. |

> Atualizar esta tabela sempre que outra ferramenta for usada (ex.: Copilot, ChatGPT, Gemini).

---

## 2. Prompts mais eficientes

### Prompt 1 — Diagrama de classes (Unidade I)

Funcionou bem por dar contexto do app, objetivo, regras de nomenclatura e formato de entrega, e por pedir que a IA declarasse as suposições em vez de inventar.

```text
CONTEXTO
Estou desenvolvendo o "Enchente Alerta", um aplicativo mobile (Flutter, Dart e Firebase) que envia alertas de alagamento em tempo real para moradores de regiões de risco. O slogan do app é "Informação que te protege". O app tem as telas de Login, Cadastro, Recuperar senha e Perfil, e uma barra de navegação com Início (mapa), Avisos, Histórico, Perfil e Guia.

Meu repositório de documentação contém: requisitos, personas, benchmark, estudo de caso, pesquisa e protótipos de baixa e alta fidelidade.

OBJETIVO
Me ajude a desenvolver o diagrama de classes (modelo de domínio) do app, representando as principais entidades, seus atributos, métodos e relacionamentos.

O QUE PRECISO
1. Identificar as entidades principais do domínio (por exemplo: Usuário, Endereço, Alerta, Área de risco, Estação de monitoramento, Mapa, Notificação, Histórico e Guia).
2. Para cada classe, definir:
   - atributos, com nome e tipo;
   - métodos principais, com parâmetros e retorno.
3. Definir os relacionamentos entre as classes, indicando:
   - o tipo (associação, agregação, composição, dependência);
   - a cardinalidade (1, 0..1, 0..*, 1..*);
   - um rótulo que explique cada relação.
4. Incluir enumerações quando fizer sentido, como o nível de alerta.

REGRAS
- Nomes de classes, atributos e métodos em português, sem acentos, no padrão camelCase (PascalCase para classes).
- Foco no domínio: sem classes de tela, widgets ou detalhes de infraestrutura.
- Cada classe deve ter uma responsabilidade clara.
- Se algo estiver ambíguo, diga qual suposição você adotou em vez de inventar em silêncio.

FORMATO DA ENTREGA
- Um diagrama renderizado, usando Mermaid (classDiagram).
- Um arquivo HTML de no máximo 200 linhas, que eu possa abrir direto no navegador.
- Depois do diagrama, um resumo curto explicando as entidades, os principais relacionamentos e as suposições feitas.
- No final, me diga quais documentos do repositório seriam úteis para refinar o modelo.
```

### Prompt 2 — Diagrama de casos de uso (Unidade I) — Pedro Fraife

Conversa em etapas: primeiro perguntar o que enviar, depois enviar só o arquivo necessário.

```text
preciso fazer um diagrama de casos de uso de um projeto meu utilizando as regras de negocio, e eu tenho esse github, qual arquivo eu te mando para fazermos e qual site eu uso para criar?
```

Em seguida: foto da estrutura de arquivos do GitHub e envio do arquivo de requisitos.

### Prompt 3 — Análise dos diagramas frente ao enunciado da Unidade II — Vinicius Reis

Funcionou bem por dar à IA o link do repositório e o PDF do enunciado, e pedir uma comparação do que existe com o que é exigido.

```text
[link do repositório + PDF "Projeto Unidade II"]
vamos para os diagramas: o que precisa ser adicionado, como estão atualmente os diagramas e o que precisa ser modificado?
```

Resultado: lista de erros de UML no diagrama de casos de uso, classes faltando no diagrama de classes e os artefatos novos exigidos (modelagem do Firestore, mapeamento Dart → Firestore e fluxo de navegação).

### Prompt 4 — Refazer o diagrama de casos de uso com a regra de acesso do grupo — Vinicius Reis

Funcionou bem por explicar a regra de negócio com as palavras do grupo antes de pedir o diagrama.

```text
a nossa ideia é que o usuário pode simplesmente se informar no app onde tem lugares de enchentes ou ruas obstruídas, ou ele pode fazer login, ter uma conta, e ele mesmo adicionar algum alerta. nossa ideia também é que o app faça download em cache e fique com as rotas, como o google maps.
```

Seguido de: `você consegue refazer e substituir no repositório com base em commits meus?`

Resultado: atores Visitante, Usuário cadastrado e Defesa Civil com herança, casos de login e controle de acesso.

### Prompt 5 — Inicializar o Firebase e criar o tema (código) — Vinicius Reis

Funcionou bem porque o contexto do projeto, as regras e a lista de próximos passos ficam no `CLAUDE.md`. Assim, o pedido pode ser curto.

```text
Leia o CLAUDE.md e comece pelo passo 1 dos próximos passos.
```

Resultado: Firebase inicializado no `main.dart` e tema claro/escuro com as cores do protótipo (`lib/theme/app_theme.dart`). Testado com `flutter analyze`, `flutter test` e no emulador.

Decisão revisada pelo grupo: o RNF10 fala em "azul-escuro e amarelo", mas as cores extraídas do protótipo de alta fidelidade mostram laranja (`#FF8D28`) como destaque. Seguimos o protótipo, porque a nota cobra fidelidade a ele.

Prompt (tela Início): enviada a imagem da tela "01 Início" do protótipo com o pedido "fazer essa tela igualzinho como está", junto do repositório.

Resultado: tela Início, barra de navegação inferior e abas provisórias (`lib/screens/`, `lib/widgets/`). Mapa com `flutter_map` e `latlong2`. Pendente validar com `flutter pub get`, `flutter analyze`, `flutter test` e no emulador.

### Prompt 6 — Classes de domínio (lib/models) — Vinicius Reis

Funcionou bem porque o diagrama de classes e a modelagem do Firestore já estavam prontos no repositório, e o plano em sprints dizia qual era a tarefa.

```text
Vamos iniciar a tarefa 1 do pdf
```

Resultado: 11 classes e 7 enumerações em `lib/models/`, com `fromFirestore`/`toFirestore`, e 13 testes do mapeamento em `test/models_test.dart`. Validado com `flutter analyze` e `flutter test`.

### Prompt 7 — Corrigir as telas de conta e ligar ao Firebase Auth — Christian Gonçalves

Funcionou bem porque foi enviado junto o guia de correção do PR (lista de arquivos, imports, cores e comandos do Firebase), então a IA não precisou adivinhar a estrutura do projeto.

```text
[guia "Enviar as telas de conta pelo Git" em PDF]
Preciso corrigir os arquivos das telas de conta na branch feature/telas-conta,
seguindo o que está escrito no PR.
```

Resultado: arquivos movidos para `lib/screens/conta/`, `lib/services/` e `lib/widgets/`; cores trocadas pelo `colorScheme` do tema; `AuthService` com Firebase Auth e mensagens em português; aba Perfil mostrando o login para o Visitante. Decisões revisadas: a barra inferior própria das telas (`AppShell`) foi retirada porque duplicava a navegação e bloqueava o Visitante; recuperar senha passou a usar o e-mail do Firebase; "Endereço padrão" ficou para depois, porque precisa da localização no mapa. Validar com `flutter analyze`, `flutter test` e no emulador antes de marcar o PR como pronto.

### Prompt 8 — Regras de segurança do Firestore — Vinicius Reis

Funcionou bem porque a tabela de acesso por perfil já estava em `docs/modelagem-firestore.md` e a IA conferiu os campos que cada classe de `lib/models/` grava antes de escrever as validações.

```text
vamos fazer essa das regras do firestore
```

Resultado: `firestore.rules` com controle de acesso por perfil, anonimato do autor (RNF07) e validação dos campos, e 23 testes no emulador do Firestore (`firestore-testes/`). Validado com `npm test` no emulador, `flutter analyze` e `flutter test`.

### Prompt 9 — Mapa e rotas no estilo Waze desviando das enchentes — Pedro Fraife

Funcionou bem porque a IA perguntou antes de começar as decisões que mudavam o resultado (serviço de rotas, o que entra no "estilo Waze" e quando um aviso de morador passa a desviar a rota), em vez de adivinhar.

```text
queria que o mapa e as rotas fossem no estilo do waze e que ele evitasse
certas rotas baseado na enchente que será avisada tanto por usuarios quanto
pela defesa civil.
```

Resultado: GPS real, rotas pelo OpenRouteService desviando das áreas da Defesa Civil e dos avisos com 2+ confirmações, navegação curva a curva e botão de reportar. Decisões do grupo: OpenRouteService (grátis e aceita áreas a evitar), aviso de morador só desvia a rota depois de confirmado por mais alguém (evita que um aviso falso desvie todo mundo). Validar com `flutter analyze`, `flutter test` e no emulador.

### Prompt 10 — Telas Histórico, Guia de segurança e Ajuda — Bernardo Gonçalves do Carmo

Funcionou bem porque foram enviados o repositório atual (`develop`), o ZIP antigo com a tela de Histórico já feita e o link do protótipo no Figma, então a IA reaproveitou o visual da tela antiga e adaptou ao que o projeto já tinha (models, tema e widgets).

```text
Eu tenho as telas 6, 8 e 13 para fazer. O primeiro ZIP é o repositório de como está
agora e o segundo é um antigo, mas com o front da tela 6 feito. Você poderia fazer
essas telas para mim?
```

Resultado: telas Histórico, Guia de segurança e Ajuda em `lib/screens/`, usando `Ocorrencia`, `GuiaOrientacao` e `FaseGuia` de `lib/models/`; botão de ajuda do cabeçalho ligado à tela Ajuda. Validar com `flutter analyze`, `flutter test` e no emulador antes de abrir o PR.

---

## 3. Erros gerados pela IA e como o grupo resolveu

| # | Artefato | Erro da IA | Como foi identificado | Solução |
|---|---|---|---|---|
| 1 | Diagrama de classes (Unid. I) | Incluiu a classe `Mapa`, que é uma tela, mesmo com a regra do prompt pedindo para não incluir telas. | Revisão do diagrama contra as regras do próprio prompt. | `Mapa` removida na versão da Unidade II. |
| 2 | Diagrama de classes (Unid. I) | Incluiu `EstacaoMonitoramento`, que não existe nos requisitos. | Comparação com `docs/requisitos.md`. | Classe removida; a origem do alerta passou a ser o campo `Alerta.origem` (meteorológica ou comunidade). |
| 3 | Diagrama de classes (Unid. I) | Usou 4 níveis de alerta (Baixo, Moderado, Alto, Crítico), mas o protótipo usa 3. | Comparação com o protótipo de alta fidelidade. | Enumeração trocada por `Gravidade` com Leve, Moderado e Grave. |
| 4 | Diagrama de classes (Unid. I) | Faltava a classe `Ocorrencia`, centro do app (comunicar alagamento, mapa de pontos, CRUD de Ocorrência), além de Abrigo, RotaFuga e Denuncia. | Comparação com os CRUDs e com o RF02/RF03. | Classes adicionadas na versão da Unidade II. |
| 5 | Diagrama de classes (Unid. I) | Criou `OcorrenciaHistorica` como classe separada, duplicando dados. | Revisão do modelo. | Removida; o histórico é uma consulta das ocorrências resolvidas ou expiradas. |
| 6 | Diagrama de casos de uso (Unid. II) | O primeiro desenho gerado com layout automático deixou as linhas dos atores cruzando as elipses dos casos de uso, ficando ilegível. | Conferência visual da imagem gerada. | Diagrama refeito com posições fixas de cada elemento (`docs/fontes/diagrama-casos-de-uso.dot`). |
| 7 | Modelagem do Firestore (exemplo de código) | Usou enums em maiúsculas (`GRAVE`, `ALAGAMENTO`), lidos com `values.byName`. O lint do Flutter (`constant_identifier_names`) aponta isso como fora do padrão do Dart. | `flutter analyze` ao criar as classes de `lib/models/`. | Valores no padrão do Dart (`Gravidade.grave`), cada um com o campo `codigo` gravado no Firestore (`"GRAVE"`). O banco ficou igual e o exemplo do documento foi corrigido. |
| 8 | Telas Rota de fuga e Abrigos próximos | Criou models próprios `Abrigo` e `RotaFuga`, sobrescrevendo os models existentes do grupo ao extrair o ZIP sobre o projeto e causando falha em `test/models_test.dart`. | Falha nos testes após a extração dos arquivos. | Telas refeitas para utilizar os models que já existiam no projeto, e arquivos originais restaurados com `git restore`. |
| 9 | Testes de widget das telas de rota e abrigos | Os testes aguardavam pouco tempo para a troca de tela, não acompanhando o tempo necessário para a navegação. | Falhas nos testes de widget durante a validação da navegação. | Espera dos testes ajustada para ocorrer em dois passos, permitindo aguardar a troca de tela corretamente. |
| 10 | Regras do Firestore (esboço da modelagem) | O esboço deixava criar ocorrência sem gravar o autor (o autor não conseguiria excluí-la), permitia se registrar como autor de uma ocorrência de outra pessoa e não validava nenhum campo. | Testes das regras no emulador do Firestore. | Ocorrência e autor gravados juntos e conferidos com `getAfter`; validação de campos, tipos e valores em cada coleção (`firestore.rules`). |
| 11 | `AuthService` (cadastro) | Gravava em `usuarios/{uid}` o e-mail como foi digitado, mas o Firebase guarda o e-mail em minúsculas; com a regra que exige o e-mail do login, o documento seria recusado. | Revisão do cadastro contra as regras novas. | O documento passa a usar o e-mail devolvido pelo Firebase (`user.email`). |
| 12 | Rotas com o OpenRouteService | Usou o endereço `api.openrouteservice.org`, que foi desativado em 2026 em favor de `api.heigit.org`. | Aviso no painel da chave do OpenRouteService. | Endereços trocados para `api.heigit.org/openrouteservice` (rotas) e `api.heigit.org/pelias/v1` (endereços) em `lib/services/rotas_service.dart`. |
| 13 | Rotas e navegação | O código foi escrito sem compilar no ambiente da IA (download do Flutter bloqueado). | A própria IA avisou. | Validação feita pelo grupo com `flutter analyze`, `flutter test` e no emulador antes do PR. |
| 14 | Fundo do mapa | Trocou o OpenStreetMap pela CARTO sem chave, mas a CARTO passou a exigir chave em 2026; o mapa apareceu com a marca d'água "API KEY REQUIRED". | Teste no emulador. | OpenStreetMap volta a ser o padrão; a CARTO só é usada com a chave opcional `CARTO_API_KEY` (`lib/widgets/mapa/mapa_enchente.dart`). |
| 15 | Confirmações de aviso ("Ainda está aí") | Criou o campo `confirmacoes` e a subcoleção `confirmacoes/{uid}` sem mudar o `firestore.rules`; com as regras publicadas, reportar e confirmar seriam recusados. O esboço de regras sugerido no documento tirava as validações de campos. | Revisão do PR contra as regras publicadas (os testes do app usam um Firestore falso, que não aplica regras). | Confirmações acrescentadas ao `firestore.rules`, mantendo as validações: aviso novo com 1 confirmação, soma de exatamente 1 por pessoa e prazo de no máximo 5 h; 7 testes novos no emulador. |
| 16 | Mapa (ponto do usuário) | O ponto azul do usuário era desenhado por cima dos avisos e bloqueava o toque; o aviso reportado na própria posição não podia ser aberto. | Teste no emulador (o teste de widget só tocava em avisos longe do usuário). | Ponto azul com `IgnorePointer` e teste de widget que toca no ponto e espera abrir o aviso. |
| 17 | `AuthService` (cadastro) | O cadastro e o login automático criavam `usuarios/{uid}` ao mesmo tempo; a segunda gravação chegava como alteração de `criadoEm` e era recusada pelas regras. | Erro `PERMISSION_DENIED` no log durante o teste no emulador. | Documento criado numa transação que só grava se ainda não existir; conferido criando uma conta nova no emulador. |

> Registrar aqui também os erros que aparecerem no código Flutter (ex.: pacote incompatível, erro de compilação, regra do Firestore bloqueando leitura), com o trecho corrigido ou o commit da correção.

---

## 4. Justificativa das bibliotecas escolhidas

A stack Dart + Flutter + Firebase (Autenticação e Banco de Dados) é obrigatória pela disciplina. As bibliotecas abaixo são as **previstas** para o app; a versão final será confirmada quando o código for implementado.

| Biblioteca | Para quê | Por que esta |
|---|---|---|
| `firebase_core` | Inicializar o Firebase no app. | Obrigatória para qualquer serviço Firebase no Flutter. |
| `firebase_auth` | Criar conta, login, logout e recuperar senha. | Exigência da disciplina; já trata envio de e-mail de recuperação de senha. |
| `cloud_firestore` | Ocorrências, alertas, abrigos, rotas, usuários e denúncias. | Exigência da disciplina; atualiza o mapa em tempo real (RF09) e mantém cache local quando a conexão cai. |
| `flutter_map` + `latlong2` | Exibir o mapa, pontos de alagamento, abrigos e rotas. | Usa mapas do OpenStreetMap, sem chave de API paga, e permite guardar a região em cache. O Google Maps não permite que apps de terceiros baixem o mapa para uso offline. |
| `flutter_map_tile_caching` | Baixar a região do mapa para uso sem internet (RF07, RNF05). | Integra com o `flutter_map` e faz o download da região escolhida. |
| `geolocator` | Obter a localização do usuário (abrigos próximos, informar localização). | Pacote mais usado para GPS no Flutter, com tratamento de permissão. |
| `http` | Chamar o OpenRouteService (rotas e busca de endereços). | Pacote oficial do Dart para requisições HTTP; tem `MockClient` para testar sem internet. |
| OpenRouteService (serviço) | Calcular rotas que desviam das áreas alagadas (`avoid_polygons`). | Gratuito (2.000 rotas/dia) e aceita áreas a evitar. O Google Maps só evita pedágio/rodovia e é pago após a cota. |
| CARTO (fundo do mapa, opcional) | Visual limpo do mapa, claro e escuro. | Chave grátis até 5 milhões de blocos/mês (uso não comercial), dados do OpenStreetMap; sem a chave o app usa o OpenStreetMap padrão. |
| `connectivity_plus` | Detectar falta de internet e avisar o usuário. | Necessário para o tratamento de falhas de conexão pedido no enunciado. |
| `image_picker` | Tirar ou escolher a foto da ocorrência. | Pacote oficial da equipe do Flutter para câmera e galeria. |

> Ponto em aberto: guardar fotos exige o Firebase Storage, que hoje pede o plano pago (Blaze) em projetos novos. Se o grupo não ativar esse plano, a foto da ocorrência fica fora do escopo ou é guardada de outra forma.

---

## 5. Como o grupo valida o que a IA produz

- Todo diagrama gerado é comparado com `docs/requisitos.md`, os CRUDs e o protótipo de alta fidelidade antes de entrar no repositório.
- As suposições feitas pela IA ficam registradas nos próprios documentos (ex.: seção "Pontos em aberto" em `docs/diagrama-de-classes.md`).
- As regras do Firestore geradas com IA são testadas no emulador do Firestore (`firestore-testes/`, 30 testes) antes de serem aplicadas no projeto.
- Código gerado por IA só é enviado depois de compilar e rodar no emulador, e cada integrante deve saber explicar o trecho que enviou, já que o projeto tem arguição oral.
