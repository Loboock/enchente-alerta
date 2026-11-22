import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../data/dados_provisorios.dart';
import '../models/models.dart';
import 'auth_service.dart';
import 'erro_servico.dart';

/// Abrigos da coleção `abrigos`, em tempo real.
///
/// Os moradores veem os abrigos cadastrados pela Defesa Civil. Enquanto não
/// houver nenhum cadastrado (ou sem Firebase, nos testes), aparecem os
/// abrigos de exemplo, para o app nunca ficar sem abrigos.
class AbrigosService {
  AbrigosService();

  /// Trocável nos testes por uma versão falsa.
  static AbrigosService instance = AbrigosService();

  /// Só os abrigos gravados no Firestore (tela da Defesa Civil).
  final cadastrados = ValueNotifier<List<Abrigo>>(const []);

  StreamSubscription<Object?>? _assinatura;

  /// O que os moradores veem: os cadastrados ou, sem nenhum, os de exemplo.
  List<Abrigo> get paraMoradores =>
      cadastrados.value.isEmpty ? abrigosDeExemplo : cadastrados.value;

  bool get usandoExemplos => cadastrados.value.isEmpty;

  /// Abrigos ativos, do mais perto para o mais longe de [de].
  List<Abrigo> porDistancia(LatLng de) {
    final lista = paraMoradores.where((a) => a.ativo).toList()
      ..sort((a, b) => a.distanciaAte(de).compareTo(b.distanciaAte(de)));
    return lista;
  }

  void iniciar() {
    if (_assinatura != null) return;
    final db = firestoreOuNull();
    if (db == null) return;
    _assinatura = db.collection('abrigos').snapshots().listen(
      (snap) {
        final lista = <Abrigo>[];
        for (final doc in snap.docs) {
          try {
            lista.add(Abrigo.fromFirestore(doc));
          } catch (e) {
            debugPrint('Abrigo ignorado: $e');
          }
        }
        lista.sort((a, b) => a.nome.compareTo(b.nome));
        cadastrados.value = lista;
      },
      onError: (Object e) => debugPrint('abrigos: $e'),
    );
  }

  /// Cria (id vazio) ou altera um abrigo, registrando quem alterou.
  Future<void> salvar(Abrigo abrigo) async {
    final db = firestoreObrigatorio();
    final colecao = db.collection('abrigos');
    final ref = abrigo.id.isEmpty ? colecao.doc() : colecao.doc(abrigo.id);
    final dados = Abrigo(
      id: ref.id,
      nome: abrigo.nome,
      bairro: abrigo.bairro,
      localizacao: abrigo.localizacao,
      capacidade: abrigo.capacidade,
      vagasDisponiveis: abrigo.vagasDisponiveis,
      ativo: abrigo.ativo,
      atualizadoPor: AuthService.instance.user?.uid,
      atualizadoEm: DateTime.now(),
    ).toFirestore();
    await gravarNoFirestore(() => ref.set(dados));
  }

  /// Muda só as vagas (botões − e + da lista).
  Future<void> alterarVagas(Abrigo abrigo, int vagas) => salvar(Abrigo(
        id: abrigo.id,
        nome: abrigo.nome,
        bairro: abrigo.bairro,
        localizacao: abrigo.localizacao,
        capacidade: abrigo.capacidade,
        vagasDisponiveis: vagas.clamp(0, abrigo.capacidade),
        ativo: abrigo.ativo,
      ));

  Future<void> excluir(Abrigo abrigo) async {
    final db = firestoreObrigatorio();
    await gravarNoFirestore(
        () => db.collection('abrigos').doc(abrigo.id).delete());
  }

  /// Grava os abrigos de exemplo no Firestore, para a Defesa Civil começar
  /// a partir deles em vez de cadastrar tudo do zero.
  Future<void> cadastrarExemplos() async {
    final db = firestoreObrigatorio();
    final uid = AuthService.instance.user?.uid;
    final lote = db.batch();
    for (final a in abrigosDeExemplo) {
      lote.set(
        db.collection('abrigos').doc(a.id),
        Abrigo(
          id: a.id,
          nome: a.nome,
          bairro: a.bairro,
          localizacao: a.localizacao,
          capacidade: a.capacidade,
          vagasDisponiveis: a.vagasDisponiveis,
          atualizadoPor: uid,
          atualizadoEm: DateTime.now(),
        ).toFirestore(),
      );
    }
    await gravarNoFirestore(lote.commit);
  }

  void parar() {
    _assinatura?.cancel();
    _assinatura = null;
  }
}

