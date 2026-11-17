# Testes das regras do Firestore

Testa o arquivo [`../firestore.rules`](../firestore.rules) no emulador local do Firestore. Não acessa o banco real.

O arquivo [`regras.test.js`](regras.test.js) tem 30 testes que verificam o acesso do Visitante, do Morador e da Defesa Civil, o anonimato do autor (RNF07), as confirmações de aviso ("Ainda está aí") e a validação dos campos.

## Precisa ter instalado

- Node.js
- Firebase CLI: `npm install -g firebase-tools`
- Java 11 ou mais novo. Serve o que vem com o Android Studio: `C:\Program Files\Android\Android Studio\jbr\bin`, que precisa estar no PATH.

## Como rodar

Dentro desta pasta:

```bash
npm install
npm test
```

O resultado esperado é `pass 30` e `fail 0`. As mensagens `PERMISSION_DENIED` que aparecem no meio da saída são normais: são os testes que conferem que a regra bloqueia.

## Depois de mudar as regras

1. Rode `npm test` de novo.
2. Na raiz do repositório, aplique no projeto do Firebase com `firebase deploy --only firestore:rules`. Isso é feito só pelo Vinicius, depois do merge na `develop`.
