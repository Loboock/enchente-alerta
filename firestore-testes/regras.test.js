// Testes das regras do Firestore (../firestore.rules) no emulador local.
// Não acessa o banco real. Como rodar: ver README.md desta pasta.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  GeoPoint,
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

let env;

const agora = Timestamp.now();
const daqui6h = Timestamp.fromMillis(agora.toMillis() + 6 * 3600 * 1000);

const ocorrencia = () => ({
  tipo: 'ALAGAMENTO',
  gravidade: 'MODERADO',
  status: 'ATIVA',
  endereco: 'Av. Murilo Dantas, Farolândia',
  localizacao: new GeoPoint(-10.964, -37.051),
  nivelAguaCm: 40,
  criadaEm: agora,
  expiraEm: daqui6h,
});

const usuario = (email, perfil = 'MORADOR') => ({
  email,
  nome: 'Ana',
  perfil,
  criadoEm: agora,
  preferenciaNotificacao: { ativa: true, raioKm: 2 },
});

const abrigo = () => ({
  nome: 'Escola Exemplo',
  bairro: 'Farolândia',
  localizacao: new GeoPoint(-10.97, -37.05),
  capacidade: 200,
  vagasDisponiveis: 50,
  ativo: true,
});

// Contextos: Visitante, dois moradores e a Defesa Civil.
const visitante = () => env.unauthenticatedContext().firestore();
const ana = () => env.authenticatedContext('ana', { email: 'ana@exemplo.com' }).firestore();
const bia = () => env.authenticatedContext('bia', { email: 'bia@exemplo.com' }).firestore();
const defesa = () => env.authenticatedContext('dc', { email: 'dc@exemplo.com' }).firestore();

// Grava sem passar pelas regras (prepara o cenário do teste).
const semRegras = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

// Ana registra uma ocorrência do jeito que o app vai fazer: ocorrência e
// autor na mesma gravação.
async function anaRegistra(id = 'oc1', dados = ocorrencia()) {
  const db = ana();
  const batch = writeBatch(db);
  batch.set(doc(db, 'ocorrencias', id), dados);
  batch.set(doc(db, 'autoresOcorrencias', id), { autorId: 'ana' });
  return batch.commit();
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-enchente-alerta',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await semRegras(async (db) => {
    await setDoc(doc(db, 'usuarios/ana'), usuario('ana@exemplo.com'));
    await setDoc(doc(db, 'usuarios/bia'), usuario('bia@exemplo.com'));
    await setDoc(doc(db, 'usuarios/dc'), usuario('dc@exemplo.com', 'DEFESA_CIVIL'));
  });
});

after(() => env.cleanup());

describe('Visitante (sem conta)', () => {
  test('lê ocorrências, abrigos, rotas, alertas, áreas e guias', async () => {
    await anaRegistra();
    for (const caminho of ['ocorrencias/oc1', 'abrigos/a', 'rotasFuga/r', 'alertas/a',
      'areasRisco/a', 'guias/g']) {
      await assertSucceeds(getDoc(doc(visitante(), caminho)));
    }
  });

  test('não registra ocorrência nem cria abrigo', async () => {
    await assertFails(setDoc(doc(visitante(), 'ocorrencias/x'), ocorrencia()));
    await assertFails(setDoc(doc(visitante(), 'abrigos/x'), abrigo()));
  });

  test('não vê quem registrou a ocorrência (RNF07)', async () => {
    await anaRegistra();
    await assertFails(getDoc(doc(visitante(), 'autoresOcorrencias/oc1')));
  });
});

describe('usuarios/{uid}', () => {
  test('cria a própria conta como MORADOR', async () => {
    await semRegras((db) => deleteDoc(doc(db, 'usuarios/ana')));
    await assertSucceeds(setDoc(doc(ana(), 'usuarios/ana'), usuario('ana@exemplo.com')));
  });

  test('não cria a conta já como DEFESA_CIVIL', async () => {
    await semRegras((db) => deleteDoc(doc(db, 'usuarios/ana')));
    await assertFails(setDoc(doc(ana(), 'usuarios/ana'),
      usuario('ana@exemplo.com', 'DEFESA_CIVIL')));
  });

  test('não usa e-mail diferente do login', async () => {
    await semRegras((db) => deleteDoc(doc(db, 'usuarios/ana')));
    await assertFails(setDoc(doc(ana(), 'usuarios/ana'), usuario('outro@exemplo.com')));
  });

  test('muda o nome e as notificações, mas não o próprio perfil', async () => {
    await assertSucceeds(updateDoc(doc(ana(), 'usuarios/ana'),
      { nome: 'Ana Souza', preferenciaNotificacao: { ativa: false, raioKm: 5 } }));
    await assertFails(updateDoc(doc(ana(), 'usuarios/ana'), { perfil: 'DEFESA_CIVIL' }));
  });

  test('não lê nem altera a conta de outra pessoa', async () => {
    await assertFails(getDoc(doc(bia(), 'usuarios/ana')));
    await assertFails(updateDoc(doc(bia(), 'usuarios/ana'), { nome: 'X' }));
  });

  test('endereços são só do dono', async () => {
    const endereco = {
      logradouro: 'Rua A', bairro: 'Farolândia', cidade: 'Aracaju',
      localizacao: new GeoPoint(-10.96, -37.05), padrao: true,
    };
    await assertSucceeds(setDoc(doc(ana(), 'usuarios/ana/enderecos/e1'), endereco));
    await assertFails(getDoc(doc(bia(), 'usuarios/ana/enderecos/e1')));
  });
});

describe('ocorrencias', () => {
  test('morador registra ocorrência junto com o autor', async () => {
    await assertSucceeds(anaRegistra());
  });

  test('ocorrência sem o autor é recusada', async () => {
    await assertFails(setDoc(doc(ana(), 'ocorrencias/oc1'), ocorrencia()));
  });

  test('não grava o autor como outra pessoa', async () => {
    const db = ana();
    const batch = writeBatch(db);
    batch.set(doc(db, 'ocorrencias', 'oc1'), ocorrencia());
    batch.set(doc(db, 'autoresOcorrencias', 'oc1'), { autorId: 'bia' });
    await assertFails(batch.commit());
  });

  test('não se apropria de ocorrência que já existe', async () => {
    await anaRegistra();
    await assertFails(setDoc(doc(bia(), 'autoresOcorrencias/oc1'), { autorId: 'bia' }));
  });

  test('validações: tipo, gravidade, nível da água, campos extras e autor no documento', async () => {
    await assertFails(anaRegistra('a', { ...ocorrencia(), tipo: 'INCENDIO' }));
    await assertFails(anaRegistra('b', { ...ocorrencia(), gravidade: 'CRITICO' }));
    await assertFails(anaRegistra('c', { ...ocorrencia(), nivelAguaCm: -5 }));
    await assertFails(anaRegistra('d', { ...ocorrencia(), nivelAguaCm: 40.5 }));
    await assertFails(anaRegistra('e', { ...ocorrencia(), endereco: '' }));
    await assertFails(anaRegistra('f', { ...ocorrencia(), autorId: 'ana' }));
    await assertFails(anaRegistra('g', { ...ocorrencia(), status: 'RESOLVIDA' }));
    await assertFails(anaRegistra('h', { ...ocorrencia(), expiraEm: agora }));
  });

  test('descrição é opcional', async () => {
    await assertSucceeds(anaRegistra('oc2', { ...ocorrencia(), descricao: 'Água na canela' }));
  });

  test('autor exclui a própria ocorrência; outro morador não', async () => {
    await anaRegistra();
    await assertFails(deleteDoc(doc(bia(), 'ocorrencias/oc1')));
    await assertSucceeds(deleteDoc(doc(ana(), 'ocorrencias/oc1')));
    await assertSucceeds(deleteDoc(doc(ana(), 'autoresOcorrencias/oc1')));
  });

  test('autor vê que é o autor; outro morador não', async () => {
    await anaRegistra();
    await assertSucceeds(getDoc(doc(ana(), 'autoresOcorrencias/oc1')));
    await assertFails(getDoc(doc(bia(), 'autoresOcorrencias/oc1')));
  });

  test('só a Defesa Civil marca como resolvida', async () => {
    await anaRegistra();
    await assertFails(updateDoc(doc(ana(), 'ocorrencias/oc1'), { status: 'RESOLVIDA' }));
    await assertSucceeds(updateDoc(doc(defesa(), 'ocorrencias/oc1'), { status: 'RESOLVIDA' }));
    await assertSucceeds(getDoc(doc(defesa(), 'autoresOcorrencias/oc1')));
    await assertSucceeds(deleteDoc(doc(defesa(), 'ocorrencias/oc1')));
  });
});

describe('denuncias', () => {
  const denuncia = (autorId) => ({ autorId, motivo: 'AGUA_BAIXOU', criadaEm: agora });

  test('morador denuncia, mas só a Defesa Civil lê', async () => {
    await anaRegistra();
    await assertSucceeds(setDoc(doc(bia(), 'ocorrencias/oc1/denuncias/d1'), denuncia('bia')));
    await assertFails(setDoc(doc(bia(), 'ocorrencias/oc1/denuncias/d2'), denuncia('ana')));
    await assertFails(setDoc(doc(visitante(), 'ocorrencias/oc1/denuncias/d3'), denuncia('bia')));
    await assertFails(getDoc(doc(bia(), 'ocorrencias/oc1/denuncias/d1')));
    await assertSucceeds(getDoc(doc(defesa(), 'ocorrencias/oc1/denuncias/d1')));
  });
});

describe('Dados da Defesa Civil', () => {
  test('só a Defesa Civil gerencia abrigos', async () => {
    await assertFails(setDoc(doc(ana(), 'abrigos/a1'), abrigo()));
    await assertSucceeds(setDoc(doc(defesa(), 'abrigos/a1'), abrigo()));
    await assertSucceeds(updateDoc(doc(defesa(), 'abrigos/a1'), { vagasDisponiveis: 10 }));
    await assertSucceeds(deleteDoc(doc(defesa(), 'abrigos/a1')));
  });

  test('abrigo com mais vagas que a capacidade é recusado', async () => {
    await assertFails(setDoc(doc(defesa(), 'abrigos/a1'),
      { ...abrigo(), vagasDisponiveis: 300 }));
  });

  test('só a Defesa Civil gerencia rotas, alertas e guias', async () => {
    const rota = {
      abrigoId: 'a1',
      pontos: [new GeoPoint(-10.96, -37.05), new GeoPoint(-10.97, -37.05)],
      distanciaMetros: 800, tempoAPeMin: 10, tempoCarroMin: 3,
      riscoNaVia: 'LEVE', interditada: false, areasEvitadasIds: [],
    };
    await assertFails(setDoc(doc(ana(), 'rotasFuga/r1'), rota));
    await assertSucceeds(setDoc(doc(defesa(), 'rotasFuga/r1'), rota));

    const alerta = {
      titulo: 'Chuva forte', descricao: '...', nivel: 'GRAVE', origem: 'METEOROLOGICA',
      areasRiscoIds: [], ocorrenciasIds: [], guiasIds: [], emitidoEm: agora, expiraEm: daqui6h,
    };
    await assertFails(setDoc(doc(ana(), 'alertas/al1'), alerta));
    await assertSucceeds(setDoc(doc(defesa(), 'alertas/al1'), alerta));

    const guia = { titulo: 'Kit de emergência', conteudo: '...', fase: 'ANTES', ordem: 1 };
    await assertFails(setDoc(doc(ana(), 'guias/g1'), guia));
    await assertSucceeds(setDoc(doc(defesa(), 'guias/g1'), guia));
  });

  test('coleção que não está nas regras fica bloqueada', async () => {
    await assertFails(setDoc(doc(defesa(), 'qualquerCoisa/x'), { a: 1 }));
    await assertFails(getDoc(doc(visitante(), 'qualquerCoisa/x')));
  });
});
