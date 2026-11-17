# Mapa, rotas de fuga e avisos de alagamento

Como funciona e o que configurar para rodar a parte de mapa estilo Waze.

## Como o desvio funciona

1. O app junta duas fontes de perigo em tempo real (`PerigosService`):
   - **Áreas da Defesa Civil** (`areasRisco`, polígonos): sempre bloqueiam.
   - **Avisos de moradores** (`ocorrencias`, ponto + raio de 40/60/90 m
     conforme a gravidade): só bloqueiam depois de **2 confirmações**
     (quem reportou + mais uma pessoa). Antes disso aparecem em laranja no
     mapa e a tela de rota avisa "sem confirmação no caminho".
2. Ao calcular a rota (`RotasService`), os perigos que bloqueiam vão para o
   OpenRouteService em `options.avoid_polygons`, e o próprio serviço acha um
   caminho por fora deles.
3. Perigo onde a pessoa já está ou no destino não pode ser evitado (o serviço
   recusaria a rota): a tela mostra um alerta vermelho.
4. Durante a navegação, se um alagamento for confirmado à frente ou a pessoa
   sair da rota (3 leituras de GPS seguidas), a rota é recalculada.

O número de confirmações e o tempo de vida de um aviso ficam em
`lib/config.dart`.

## 1. Chave do OpenRouteService (obrigatória)

1. Crie uma conta grátis em https://openrouteservice.org/dev/#/signup
2. No painel, gere uma chave ("Request a token", plano Standard).
3. Crie `config.json` na raiz do projeto (**não suba para o git**):

   ```json
   { "ORS_API_KEY": "cole_sua_chave_aqui" }
   ```

4. Adicione `config.json` ao `.gitignore`.
5. Rode com:

   ```
   flutter run --dart-define-from-file=config.json
   ```

   No VS Code, em `.vscode/launch.json`:
   `"args": ["--dart-define-from-file=config.json"]`.
   No Android Studio: Run > Edit Configurations > Additional run args.

Sem a chave o app abre normalmente, mas a tela de rota mostra
"Falta a chave do OpenRouteService".

Plano grátis: 2.000 rotas por dia e 40 por minuto. A busca de endereços tem
cota própria. Para um projeto acadêmico, dá para pedir o plano
"Collaborative" (10.000 rotas/dia) no próprio painel.

Atenção: a chave vai dentro do app e pode ser extraída do APK. Para um
produto de verdade, o certo é chamar o ORS por um servidor seu (por exemplo,
uma Cloud Function).

## 2. Permissões no Android

Já estão em `android/app/src/main/AndroidManifest.xml` (`ACCESS_FINE_LOCATION`
e `ACCESS_COARSE_LOCATION`). Na primeira vez que o mapa abre, o app pede a
permissão de localização.

## 3. Testar no emulador

O emulador começa na Califórnia, longe dos abrigos de exemplo (Aracaju). Duas
opções:

- No emulador: `...` > Location > procure "Farolândia, Aracaju" > Set location.
- Ou rode com a posição fixa de teste:

  ```
  flutter run --dart-define-from-file=config.json --dart-define=LOCALIZACAO_TESTE=true
  ```

Para testar a navegação "andando", use Location > Routes no emulador e dê
play numa rota.

## 4. Firestore

### Campos e coleções novos

| Onde | O quê |
|---|---|
| `ocorrencias/{id}.confirmacoes` | número; começa em 1 (o autor) |
| `ocorrencias/{id}/confirmacoes/{uid}` | marca quem confirmou (1 por pessoa) |
| `ocorrencias/{id}/denuncias/{id}` | "Não está mais aqui" (motivo `AGUA_BAIXOU`) |
| `autoresOcorrencias/{id}` | `{ autorId }`, separado para manter o anonimato |

Documentos antigos sem `confirmacoes` contam como 1.

Nenhum índice composto é necessário: o app busca `status == "ATIVA"` e
descarta as expiradas localmente.

### Regras

As regras das confirmações estão em [`firestore.rules`](../firestore.rules),
explicadas em `docs/modelagem-firestore.md`, seção 5, e testadas em
`firestore-testes/`. Quem publica no Firebase é o Vinicius, com
`firebase deploy --only firestore:rules`, depois do merge na `develop`.

## 5. Fundo do mapa

- **Sem configurar nada:** OpenStreetMap padrão (escurecido no modo noturno).
- **Visual limpo, estilo Waze (opcional):** peça uma chave grátis em
  https://carto.com/basemaps/apikey (sem fila de aprovação; grátis até
  5 milhões de blocos por mês para uso não comercial) e acrescente no
  `config.json`:

  ```json
  {
    "ORS_API_KEY": "...",
    "CARTO_API_KEY": "sua_chave_carto"
  }
  ```

Desde 2026 a CARTO exige chave: sem ela, o mapa aparece com a marca d'água
"API KEY REQUIRED". O crédito do mapa na tela troca sozinho conforme o fundo.

## Arquivos

| Arquivo | Papel |
|---|---|
| `lib/config.dart` | chave do ORS, nº de confirmações, validade dos avisos |
| `lib/services/localizacao_service.dart` | GPS (permissão, posição, direção) |
| `lib/services/rotas_service.dart` | rotas com desvio e busca de endereços (ORS) |
| `lib/services/perigos_service.dart` | alagamentos ao vivo; reportar/confirmar/negar |
| `lib/models/perigo.dart` | junta aviso de morador e área da Defesa Civil |
| `lib/models/rota_calculada.dart` | rota, passos da navegação, modo carro/a pé |
| `lib/utils/geo.dart` | contas de distância e projeção na rota |
| `lib/widgets/mapa/` | mapa estilo Waze, ícones, folhas de reportar/detalhe |
| `lib/screens/rota/tela_navegacao.dart` | navegação curva a curva |
