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
| `connectivity_plus` | Detectar falta de internet e avisar o usuário. | Necessário para o tratamento de falhas de conexão pedido no enunciado. |
| `image_picker` | Tirar ou escolher a foto da ocorrência. | Pacote oficial da equipe do Flutter para câmera e galeria. |

> Ponto em aberto: guardar fotos exige o Firebase Storage, que hoje pede o plano pago (Blaze) em projetos novos. Se o grupo não ativar esse plano, a foto da ocorrência fica fora do escopo ou é guardada de outra forma.

---

## 5. Como o grupo valida o que a IA produz

- Todo diagrama gerado é comparado com `docs/requisitos.md`, os CRUDs e o protótipo de alta fidelidade antes de entrar no repositório.
- As suposições feitas pela IA ficam registradas nos próprios documentos (ex.: seção "Pontos em aberto" em `docs/diagrama-de-classes.md`).
- Código gerado por IA só é enviado depois de compilar e rodar no emulador, e cada integrante deve saber explicar o trecho que enviou, já que o projeto tem arguição oral.
