# CLAUDE.md — contexto do projeto EnchenteAlerta

Instruções e contexto para o Claude Code trabalhar neste repositório. Responder sempre em **português do Brasil**.

## O projeto

App mobile de prevenção de enchentes para moradores de áreas de risco: mapa de pontos de alagamento e vias obstruídas, avisos da comunidade, alertas, abrigos, rotas de fuga, guia de preparação e uso offline.

- Disciplina: Programação para Dispositivos Móveis — Profa. Layse Santos Souza (Unit, Ciência da Computação).
- Grupo: Vinicius Reis, Bernardo Gonçalves do Carmo, Pedro Brid do Carmo Fraife, Christian Gonçalves.
- Repositório: https://github.com/Loboock/enchente-alerta (o mesmo da Unidade I).

## Avaliação da Unidade II (resumo do enunciado)

- Apresentações: **24/11/2026** e **01/12/2026**. Link do repositório entregue no Teams; fora do prazo = nota zero.
- Stack obrigatória: **Dart, Flutter e Firebase (Authentication + Firestore)**.
- **App que não compilar ou não rodar no emulador é desconsiderado.** Nunca deixar o `main` quebrado.
- IA é permitida se documentada em `docs/uso-de-ia.md` e entendida pelo grupo (há arguição oral).
- Q1a (3,0): app fiel ao protótipo de alta fidelidade, Firebase Auth + Firestore, funcionalidades e CRUDs, regras do aditivo (controle de acesso, validações, falhas de conexão).
- Q1b (2,0): casos de uso, classes, modelagem Firestore + mapeamento Dart, **fluxo de navegação real** (ainda falta), `docs/uso-de-ia.md`.
- Q1c (1,0, individual): commits com a própria conta, README (responsabilidades reais) e CHANGELOG atualizados, sprints semanais.
- Q1d (1,0): escopo, EAP simplificada, planejamento em sprints (ainda falta).
- Q1e (1,0): protótipos de baixa e alta fidelidade.
- O **aditivo de regras de negócio** citado no enunciado ainda não foi localizado; perguntar à professora.

## Regras de trabalho neste repositório

1. **Commits feitos nesta máquina são do Vinicius** (autor `Vinicius Reis <viniciusloboock@gmail.com>`); quando feitos com apoio de IA, incluir `Co-Authored-By: Claude` na mensagem. Os colegas fazem commits com as próprias contas.
2. **Sempre registrar toda mudança no `CHANGELOG.md`**, na entrada da data do dia (formato `# [DD/MM/AAAA]` com `### Adicionado / Alterado / Removido`).
3. Antes de dar uma tarefa de código como pronta: `flutter analyze` sem erros e `flutter run` funcionando no emulador.
4. Ao fim de cada tarefa feita com IA, atualizar `docs/uso-de-ia.md` só com o essencial que o enunciado pede: ferramentas, prompts eficientes, erros da IA com a solução, bibliotecas e validação. Sem detalhes desnecessários.
5. Mensagens de commit no padrão `tipo: descrição` (`feat`, `fix`, `docs`, `refactor`), em português.
6. Não commitar `BRIEFING-EnchenteAlerta.md` (anotação local).
7. **Fluxo de branches** (detalhes em `CONTRIBUTING.md`): cada tarefa em `feature/<nome>`, criada a partir da `develop`, com PR para a `develop`. O Vinicius revisa e mescla. A `main` só recebe a `develop` quando estiver estável. Não commitar direto na `main` nem na `develop`.

## Decisões já tomadas

- **Perfis de acesso:** Visitante (sem conta) só consulta; Usuário cadastrado também registra ocorrências, exclui as próprias, reporta avisos e configura alertas; Defesa Civil também gerencia abrigos e rotas. O perfil `DEFESA_CIVIL` é definido manualmente no console; toda conta nova é `MORADOR`.
- **Anonimato (RNF07):** o autor da ocorrência fica na coleção separada `autoresOcorrencias/{ocorrenciaId}`, nunca no documento público da ocorrência.
- **Offline:** mapa com `flutter_map` (OpenStreetMap) e cache da região com `flutter_map_tile_caching`; o Firestore também mantém cache local. Google Maps não permite mapa offline para apps de terceiros.
- **Sem custos:** projeto no plano Spark. Sem Firebase Storage e sem Cloud Functions. A expiração de ocorrências é tratada pelo app (`expiraEm` no passado).
- **Foto da ocorrência:** opcional, tratada como possível melhoria futura (bônus), ainda em debate. Não está no protótipo e não é exigida pela professora.
- **Campo descrição:** mantido como opcional, embora a tela "Criar aviso" do protótipo não o tenha.

## Onde está cada coisa

| Arquivo | Conteúdo |
|---|---|
| `docs/requisitos.md` | Funcionalidades, RF01–RF09, RNF01–RNF12, CRUDs, priorização |
| `docs/prototipoAltaFidelidade.pdf.pdf` | Protótipo de alta fidelidade (13 telas) — referência visual obrigatória |
| `docs/diagrama-casos-de-uso.png` | Casos de uso da Unidade II (fonte em `docs/fontes/diagrama-casos-de-uso.dot`, gerar com `neato`) |
| `docs/diagrama-de-classes.md` | Classes de domínio, enumerações e relacionamentos (fonte Mermaid em `.mmd`) |
| `docs/modelagem-firestore.md` | Coleções, campos, mapeamento Dart ↔ Firestore e regras de segurança |
| `docs/uso-de-ia.md` | Registro de uso de IA |

## Estado atual (09/11/2026)

- Firebase: projeto `enchente-alerta`, plano Spark, Auth por e-mail/senha ativo, Firestore em `southamerica-east1`, regras ainda em modo produção (bloqueando tudo) — aplicar as regras de `docs/modelagem-firestore.md` quando o app gravar dados.
- Flutter: projeto criado na raiz (`br.unit.enchentealerta.enchente_alerta`, só Android), FlutterFire configurado, pacotes `firebase_core`, `firebase_auth`, `cloud_firestore`. `lib/main.dart` inicializa o Firebase e usa o tema de `lib/theme/app_theme.dart` (claro/escuro, segue o aparelho); a tela inicial ainda é provisória.
- Cores do protótipo: o destaque é laranja `#FF8D28` (não amarelo puro), usado como `secondary`.
- Ambiente: Windows, emulador Pixel 8 (Android 17). Precisou instalar o NDK 28.2.13676358 pelo SDK Manager.

## Próximos passos (em partes pequenas, testando cada uma)

1. ~~Inicializar o Firebase no `main.dart`; tema azul-escuro e amarelo com modo noturno (RNF02, RNF03, RNF10).~~ Feito em 09/11/2026.
2. ~~Navegação com barra inferior: Início (mapa), Avisos, Histórico, Perfil, Guia — igual ao protótipo.~~ Feito pelo Pedro em 10/11/2026 (tela Início com `flutter_map`; as outras abas mostram "Em construção").
3. Login, Criar conta e Recuperar senha com Firebase Auth, mantendo o acesso livre do Visitante.
4. ~~Classes de `lib/models/` conforme `docs/diagrama-de-classes.md`, com `fromFirestore`/`toFirestore`.~~ Feito em 10/11/2026 (branch `feature/models`). Enums com `codigo` gravado no Firestore; coordenadas em `LatLng`.
5. Criar aviso, lista de avisos e mapa de pontos; depois abrigos, rotas, guia, histórico e offline.
6. Documentos que faltam: fluxo de navegação real, escopo, EAP e sprints; atualizar README com responsabilidades reais.
