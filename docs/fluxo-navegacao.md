# Fluxo de navegação

Fluxo **real** do app, levantado do código em `lib/screens/` em 17/11/2026 (não do protótipo). Telas e nomes seguem o [protótipo de alta fidelidade](prototipoAltaFidelidade.pdf.pdf).

## Como a navegação funciona

- **Barra inferior com 5 abas**, sempre visível: Início, Avisos, Histórico, Perfil e Guia (`lib/screens/tela_principal.dart`). As abas ficam vivas ao trocar (o mapa não recarrega).
- **Telas abertas por cima** (Rota de fuga, Abrigos, Criar aviso etc.) mantêm a barra inferior. Tocar numa aba fecha as telas abertas e vai direto para ela (`irParaAba` em `lib/navegacao.dart`).
- **Botão "i"** no topo das telas mostra a ajuda própria daquela tela, com o atalho "Ver ajuda completa" para a tela Ajuda (um índice com atalho para cada tela). No Início, o "i" abre direto a tela Ajuda.
- **Visitante** (sem conta) navega por tudo. Ao tocar numa ação que grava dados (Reportar, Criar aviso, Ainda alagado, Água baixou), aparece o aviso "Entre na sua conta..." com o botão **Entrar**, que leva à aba Perfil.

## Diagrama

Retângulos são telas; retângulos arredondados são folhas e janelas que abrem por cima da tela. Linhas tracejadas pedem conta (sem login, levam ao Entrar). Linhas grossas são só da conta da Defesa Civil.

```mermaid
flowchart LR
    subgraph Abas["Barra inferior"]
        INI[Início - mapa]
        AVI[Avisos]
        HIS[Histórico]
        PER[Perfil]
        GUI[Guia de segurança]
    end

    INI -->|Abrigo| ABR[Abrigos próximos]
    INI -->|Rota de fuga| DES[Escolher destino]
    INI -.->|botão Reportar| REP([Folha Reportar])
    INI -->|toque num alagamento| DET([Folha do aviso:<br/>Ainda alagado / Água baixou])

    ABR -->|toque num abrigo| ROT[Rota de fuga]
    DES -->|abrigo ou endereço buscado| ROT
    ROT -->|Iniciar navegação| NAV[Navegação curva a curva]
    NAV -->|Encerrar| ROT

    AVI -.->|+ Criar aviso| CRI[Criar aviso]
    AVI -.->|Reportar| RPA[Reportar aviso]
    AVI -.->|Excluir - só o autor| EXC([Confirmar exclusão])
    CRI -->|Criar| AVI
    RPA -->|Enviar denúncia| AVI

    PER -->|sem conta| ENT[Entrar]
    ENT -->|Cadastrar-se| CAD[Cadastrar]
    ENT -->|Esqueceu a senha?| REC[Recuperar senha]
    CAD -->|conta criada| PER
    REC -->|e-mail enviado| ENT
    ENT -->|login| PER
    PER -->|com conta| OPC([Meus dados / Notificações / Sair])

    PER ==>|conta Defesa Civil| PAI[Painel da Defesa Civil]
    PAI --> DEN[Denúncias]
    PAI --> ALE[Alertas]
    PAI --> ABD[Abrigos - cadastro]
    ALE -->|Emitir / Editar| FAL[Formulário de alerta]
    ABD -->|Novo / Editar| FAB[Formulário de abrigo]
    DEN -->|Resolver / Manter / Excluir| DEN

    AJU[Ajuda] --> INI & AVI & HIS & GUI & PER
    AJU --> ABR & DES & CRI & CAD & REC
```

O botão "i" leva à Ajuda a partir de todas as telas (as ligações não aparecem no diagrama para não poluir).

## Transições

| De | Ação | Para | Precisa de conta |
|---|---|---|---|
| Qualquer tela | Aba da barra inferior | Aba escolhida (fecha as telas abertas por cima) | Não |
| Início | Botão "i" | Ajuda | Não |
| Outras telas | Botão "i" → "Ver ajuda completa" | Janela com a ajuda da tela → Ajuda | Não |
| Início | Abrigo | Abrigos próximos | Não |
| Início | Rota de fuga | Escolher destino | Não |
| Início | Botão Reportar (megafone) | Folha Reportar: tipo, gravidade, nível da água | Sim |
| Início | Toque num alagamento do mapa | Folha do aviso: Ainda alagado / Água baixou | Sim, para responder |
| Abrigos próximos | Toque num abrigo | Rota de fuga até o abrigo | Não |
| Escolher destino | Toque num abrigo ou endereço buscado | Rota de fuga | Não |
| Rota de fuga | Iniciar navegação | Navegação curva a curva | Não |
| Navegação | Encerrar | Volta para a Rota de fuga | Não |
| Avisos | + Criar aviso | Criar aviso; ao criar, volta para Avisos | Sim |
| Avisos | Reportar | Reportar aviso; ao enviar, volta para Avisos | Sim |
| Avisos | Excluir (só nos próprios avisos) | Janela de confirmação | Sim |
| Perfil (sem conta) | — | Mostra a tela Entrar | — |
| Entrar | Cadastrar-se | Cadastrar; ao criar a conta, volta para o Perfil | Não |
| Entrar | Esqueceu a senha? | Recuperar senha; ao enviar o e-mail, volta para Entrar | Não |
| Perfil (com conta) | Meus dados / Notificações / Sair | Janelas de edição e confirmação | Sim |
| Perfil (conta Defesa Civil) | — | A aba aparece como "Painel" e mostra o Painel da Defesa Civil | Defesa Civil |
| Painel | Denúncias | Avisos denunciados: Resolver, Manter ou Excluir (cada um com confirmação) | Defesa Civil |
| Painel | Alertas | Lista de alertas; Emitir alerta / Editar abrem o formulário; Encerrar e Excluir pedem confirmação | Defesa Civil |
| Painel | Abrigos | Lista de abrigos com − e + nas vagas; Novo abrigo / Editar abrem o formulário | Defesa Civil |
| Avisos (conta Defesa Civil) | Resolver | Janela de confirmação; o aviso sai do mapa | Defesa Civil |
| Início ou Avisos | Faixa de alerta da Defesa Civil | Folha com todos os alertas ativos | Não |
| Ajuda | Item da lista | Tela correspondente (aba ou tela aberta por cima) | Criar avisos: sim |

## Pontos a ajustar (encontrados no levantamento)

1. ~~**"?" nas telas de conta** abria uma janela de texto, e não a tela Ajuda.~~ Resolvido em 18/11/2026: todas as telas usam o mesmo botão "i" (`BotaoAjuda` em `lib/widgets/ajuda.dart`).
2. **Endereço padrão** (Perfil) ainda mostra "em breve" (previsto para a Sprint 2).
3. **Atalhos do Início** (Hosp. Universitário, Escola Exemplo, Farolândia) aparecem no topo do mapa, mas não fazem nada ao tocar. No protótipo eles indicam locais próximos; podem abrir a rota até o local.
