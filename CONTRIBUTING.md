# Como contribuir — EnchenteAlerta

## Branches

| Branch | Para quê |
|---|---|
| `main` | Versão estável, a que vai para a apresentação. Ninguém sobe direto aqui. |
| `develop` | Onde as tarefas do grupo são juntadas. Só recebe código por Pull Request. |
| `feature/<nome-da-tarefa>` | Uma branch por tarefa, criada a partir da `develop`. |

O Vinicius revisa e mescla os Pull Requests na `develop`. Quando a `develop` estiver estável, ele a leva para a `main`.

## Passo a passo

1. Atualize a `develop` e crie sua branch:
   ```bash
   git checkout develop
   git pull
   git checkout -b feature/tela-avisos
   ```
2. Faça a tarefa e os commits **com a sua própria conta do GitHub**, porque a nota de commits é individual.
3. Antes de subir:
   - rode `flutter analyze` (sem erros) e `flutter test`;
   - confira se o app abre no emulador;
   - registre a mudança no `CHANGELOG.md`, na data do dia;
   - se usou IA, registre o essencial em `docs/uso-de-ia.md`.
4. Suba a branch e abra um Pull Request **para a `develop`**:
   ```bash
   git push -u origin feature/tela-avisos
   ```
   No GitHub, clique em **Compare & pull request** e confira se a base é `develop`.
5. Espere a revisão. Se o Vinicius pedir ajustes, faça novos commits na mesma branch. O PR atualiza sozinho.

## Commits

Use o padrão `tipo: descrição`, em português:
- `feat:` funcionalidade nova;
- `fix:` correção;
- `docs:` documentação;
- `refactor:` reorganização sem mudar o comportamento.

Exemplo: `feat: cria tela de lista de avisos`.
