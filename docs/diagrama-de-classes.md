# Diagrama de classes (modelo de domínio) — EnchenteAlerta

Versão da Unidade II. Substitui o diagrama da Unidade I (`docs/diagrama_de_classes`), ajustado aos requisitos, aos CRUDs, ao protótipo de alta fidelidade e ao diagrama de casos de uso atualizado.

![Diagrama de classes](diagrama-de-classes.png)

> Fonte editável: [`diagrama-de-classes.mmd`](diagrama-de-classes.mmd). O código Mermaid abaixo é renderizado pelo próprio GitHub.

```mermaid
classDiagram
direction TB
class Usuario {
  -String id
  -String email
  -String nome
  -PerfilUsuario perfil
  -DateTime criadoEm
  +cadastrar(email, senha, nome) bool
  +entrar(email, senha) bool
  +sair() void
  +recuperarSenha(email) void
  +atualizarDados(nome) void
  +ehDefesaCivil() bool
}
class Endereco {
  -String id
  -String logradouro
  -String bairro
  -String cidade
  -double latitude
  -double longitude
  -bool padrao
  +definirComoPadrao() void
  +geocodificar() void
}
class PreferenciaNotificacao {
  -bool ativa
  -double raioKm
  +ativar() void
  +desativar() void
  +definirRaio(km) void
}
class Notificacao {
  -String id
  -String mensagem
  -DateTime enviadaEm
  -bool lida
  +enviar() void
  +marcarComoLida() void
}
class Ocorrencia {
  -String id
  -String autorId
  -TipoOcorrencia tipo
  -Gravidade gravidade
  -StatusOcorrencia status
  -String endereco
  -double latitude
  -double longitude
  -int nivelAguaCm
  -String descricao
  -String imagemUrl
  -DateTime criadaEm
  -DateTime expiraEm
  +registrar() void
  +estaAtiva() bool
  +marcarResolvida() void
  +expirar() void
  +excluir(usuarioId) bool
}
class Denuncia {
  -String id
  -String autorId
  -MotivoDenuncia motivo
  -String detalhes
  -DateTime criadaEm
  +enviar() void
}
class Alerta {
  -String id
  -String titulo
  -String descricao
  -Gravidade nivel
  -OrigemAlerta origem
  -DateTime emitidoEm
  -DateTime expiraEm
  +estaAtivo() bool
  +atualizarNivel(nivel) void
  +encerrar() void
  +notificarUsuarios() void
}
class AreaRisco {
  -String id
  -String nome
  -Gravidade nivelAtual
  -List poligono
  +contem(lat, lng) bool
  +atualizarNivel() void
}
class Abrigo {
  -String id
  -String nome
  -String bairro
  -double latitude
  -double longitude
  -int capacidade
  -int vagasDisponiveis
  -bool ativo
  +distanciaAte(lat, lng) double
  +atualizarVagas(vagas) void
  +estaDisponivel() bool
}
class RotaFuga {
  -String id
  -List pontos
  -int distanciaMetros
  -int tempoAPeMin
  -int tempoCarroMin
  -Gravidade riscoNaVia
  -bool interditada
  +estaLiberada() bool
  +interditar() void
}
class PacoteOffline {
  -String id
  -String regiao
  -List limites
  -int zoomMinimo
  -int zoomMaximo
  -double tamanhoMb
  -DateTime baixadoEm
  +baixar() void
  +atualizar() void
  +estaDisponivel() bool
  +remover() void
}
class GuiaOrientacao {
  -String id
  -String titulo
  -String conteudo
  -FaseGuia fase
  +exibir() void
  +filtrarPorFase(fase) List
}
class PerfilUsuario {
  <<enumeration>>
  MORADOR
  DEFESA_CIVIL
}
class TipoOcorrencia {
  <<enumeration>>
  ALAGAMENTO
  VIA_OBSTRUIDA
}
class Gravidade {
  <<enumeration>>
  LEVE
  MODERADO
  GRAVE
}
class StatusOcorrencia {
  <<enumeration>>
  ATIVA
  RESOLVIDA
  EXPIRADA
}
class MotivoDenuncia {
  <<enumeration>>
  INFORMACAO_INCORRETA
  AGUA_BAIXOU
  LOCALIZACAO_ERRADA
  SPAM_OU_ABUSO
}
class OrigemAlerta {
  <<enumeration>>
  METEOROLOGICA
  COMUNIDADE
}
class FaseGuia {
  <<enumeration>>
  ANTES
  DURANTE
  EVACUACAO
  DEPOIS
  EMERGENCIA
}
Usuario "1" *-- "0..1" PreferenciaNotificacao : possui
Usuario "1" o-- "0..*" Endereco : cadastra
Usuario "1" --> "0..*" Notificacao : recebe
Usuario "1" --> "0..*" Ocorrencia : registra
Usuario "1" --> "0..*" Denuncia : envia
Usuario "0..*" --> "0..*" Abrigo : gerencia
Usuario "0..*" --> "0..*" RotaFuga : gerencia
Ocorrencia "1" *-- "0..*" Denuncia : recebe
Ocorrencia "0..*" --> "0..1" AreaRisco : localizada em
Ocorrencia "0..*" --> "0..*" Alerta : pode originar
Alerta "0..*" --> "1..*" AreaRisco : afeta
Alerta "1" --> "0..*" Notificacao : gera
Alerta "0..*" --> "0..*" GuiaOrientacao : recomenda
RotaFuga "0..*" --> "1" Abrigo : leva a
RotaFuga "0..*" --> "0..*" AreaRisco : desvia de
PacoteOffline "0..*" o-- "0..*" Abrigo : inclui
PacoteOffline "0..*" o-- "0..*" RotaFuga : inclui
PacoteOffline "0..*" o-- "0..*" Ocorrencia : guarda últimas
```

## O que entrou

| Classe / enumeração | Por quê |
|---|---|
| `Ocorrencia` | Registro feito pela comunidade (alagamento ou via obstruída). Sustenta RF02, RF03, RF09 e o CRUD de Ocorrência. |
| `TipoOcorrencia` | Diferencia alagamento de via obstruída, como o grupo definiu para o app. |
| `Denuncia` | Tela "Reportar aviso", com os 4 motivos do protótipo. |
| `Abrigo` e `RotaFuga` | RF04, RF05 e o CRUD de Rota / Abrigo, gerenciados pela Defesa Civil. |
| `PacoteOffline` | RF07 e RNF05: região do mapa baixada em cache, com abrigos, rotas e últimas ocorrências, para uso sem internet. |
| `PerfilUsuario` | Diferencia morador de Defesa Civil, para o controle de acesso. |
| `Gravidade`, `StatusOcorrencia`, `MotivoDenuncia`, `OrigemAlerta`, `FaseGuia` | Substituem textos soltos por valores fixos. |

## O que mudou ou saiu

| Item | Mudança |
|---|---|
| `NivelAlerta` | Virou `Gravidade`, com os 3 níveis do protótipo: Leve, Moderado e Grave. |
| `EstacaoMonitoramento` | Saiu, pois não está nos requisitos. O campo `Alerta.origem` registra se o alerta veio de dado meteorológico ou da comunidade. |
| `Mapa` | Saiu, por ser uma tela e não uma entidade de domínio. |
| `OcorrenciaHistorica` | Saiu. O histórico é uma consulta das ocorrências resolvidas ou expiradas. |
| `GuiaOrientacao.fase` | Passou de texto para enumeração, incluindo a fase Depois. |

## Regras representadas

- **Visitante não tem classe.** Quem usa o app sem conta só consulta dados; não há nada salvo sobre ele. `Usuario` existe apenas para quem cria conta.
- **Anonimato (RNF07).** `Ocorrencia.autorId` e `Denuncia.autorId` ficam salvos só para permitir que o autor exclua o próprio registro e para controle de abuso; nunca aparecem na tela.
- **Controle de acesso.** As associações `gerencia` com `Abrigo` e `RotaFuga` valem apenas para usuários com `perfil = DEFESA_CIVIL` (`ehDefesaCivil()`).
- **Offline.** `PacoteOffline` existe só no celular (cache local), sem coleção no Firestore.

## Pontos em aberto

- O aditivo de regras de negócio da Unidade II pode exigir ajustes neste modelo.
- `PreferenciaNotificacao.raioKm` veio do diagrama original e não aparece nos requisitos.
- `Usuario.nome` aparece no Perfil, mas não na tela de Cadastro do protótipo.
