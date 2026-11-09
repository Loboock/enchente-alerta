# Rascunho: diagrama de classes corrigido

**Status:** rascunho gerado com IA, para o Christian revisar. Não substitui `docs/diagrama_de_classes` até o grupo aprovar.

```mermaid
classDiagram
direction TB
class Usuario {
  -String id
  -String email
  -String nome
  -PerfilUsuario perfil
  -DateTime criadoEm
  +cadastrar() bool
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
  -DateTime baixadoEm
  +baixar() void
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
Usuario "1" --> "0..*" PacoteOffline : baixa
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
```

## O que entrou

| Item | Por quê |
|------|---------|
| Ocorrencia | Relato da comunidade: sustenta as telas Avisos e Criar aviso, RF02, RF03 e o CRUD de Ocorrência. |
| Denuncia | Tela Reportar aviso, com os 4 motivos do protótipo. |
| Abrigo | RF05, tela Abrigos próximos e CRUD de Rota / Abrigo. |
| RotaFuga | RF04, tela Rota de fuga e CRUD de Rota / Abrigo. |
| PacoteOffline | RF07 e RNF05: mapa, abrigos e rotas baixados para uso sem internet. |
| PerfilUsuario | Diferencia morador de Defesa Civil, para o controle de acesso. |
| Enumerações | StatusOcorrencia, MotivoDenuncia, OrigemAlerta e FaseGuia substituem textos soltos. |

## O que mudou ou saiu

| Mudança | Por quê |
|---------|---------|
| NivelAlerta virou Gravidade | O protótipo usa 3 níveis: Leve, Moderado e Grave. |
| EstacaoMonitoramento saiu | Não está nos requisitos. O campo Alerta.origem registra se o alerta veio de dado meteorológico ou da comunidade. |
| Mapa saiu | É uma tela, e o próprio prompt do grupo pedia para não incluir telas. |
| OcorrenciaHistorica saiu | O Histórico vira uma consulta das ocorrências resolvidas ou expiradas, sem classe separada. |
| GuiaOrientacao.fase | Passou de texto para enumeração, incluindo a fase Depois, que falta no protótipo. |

## A confirmar

- O aditivo de regras de negócio pode mudar este modelo. Ele ainda não foi analisado.
- Ocorrencia.autorId fica guardado só para permitir o botão Excluir ao autor, e nunca pode aparecer na tela (RNF07).
- As rotas estão como dados cadastrados, conforme o CRUD. Se forem calculadas por uma API, RotaFuga passa a ser um resultado do cálculo.
- PacoteOffline existe só no celular, sem coleção no Firestore.
- O protótipo não tem tela para a Defesa Civil gerenciar abrigos e rotas. O grupo precisa decidir como isso será feito.
- Usuario.nome aparece no Perfil, mas não na tela Cadastrar do protótipo.
- PreferenciaNotificacao.raioKm veio do diagrama original e não aparece nos requisitos.
