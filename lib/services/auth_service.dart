// Autenticação com o Firebase Auth (e-mail e senha) e dados do usuário em
// `usuarios/{uid}` no Firestore (classe Usuario de lib/models/models.dart).
//
// O Visitante usa o app sem conta: este serviço só é chamado quando a pessoa
// abre a aba Perfil ou faz uma ação que exige login.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Erro já traduzido para mostrar na tela.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  AuthService._() {
    try {
      _auth = FirebaseAuth.instance;
    } catch (_) {
      // Firebase não inicializado (ex.: flutter test). O app continua
      // funcionando como Visitante.
      _auth = null;
    }
    final auth = _auth;
    if (auth != null) {
      _user = auth.currentUser;
      // Avisa as telas quando a pessoa entra ou sai (dispara já na abertura).
      auth.authStateChanges().listen(_aoMudarUsuario);
    }
  }

  static final instance = AuthService._();

  FirebaseAuth? _auth;
  User? _user;
  Usuario? _usuario;

  /// Usuário logado no Firebase Auth, ou null para o Visitante.
  User? get user => _user;

  /// Documento `usuarios/{uid}`, quando já foi possível ler do Firestore.
  Usuario? get usuario => _usuario;

  /// E-mail lembrado pelo "Salvar login" (só enquanto o app está aberto).
  String? savedEmail;

  String get nome {
    final u = _user;
    if (u == null) return '';
    final doBanco = _usuario?.nome;
    if (doBanco != null && doBanco.isNotEmpty) return doBanco;
    final daConta = u.displayName;
    if (daConta != null && daConta.isNotEmpty) return daConta;
    return (u.email ?? '').split('@').first;
  }

  bool get notificacoesAtivas =>
      _usuario?.preferenciaNotificacao?.ativa ?? true;

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      FirebaseFirestore.instance.collection('usuarios');

  FirebaseAuth _exigirAuth() {
    final auth = _auth;
    if (auth == null) {
      throw AuthException('Login indisponível no momento. Tente mais tarde.');
    }
    return auth;
  }

  void _aoMudarUsuario(User? u) {
    _user = u;
    if (u == null || _usuario?.id != u.uid) _usuario = null;
    notifyListeners();
    if (u != null) _carregarUsuario(u.uid);
  }

  Future<void> _carregarUsuario(String uid) async {
    try {
      final doc = await _usuarios.doc(uid).get();
      if (_user?.uid != uid) return;
      if (doc.exists) {
        _usuario = Usuario.fromFirestore(doc);
        notifyListeners();
      } else {
        // Conta nova (ou criada antes das regras): cria o documento agora.
        final u = _user!;
        await _criarDocumentoUsuario(
            uid, u.email ?? '', nome.isEmpty ? 'Morador' : nome);
      }
    } catch (e) {
      // Regras do Firestore ainda bloqueiam a leitura: segue só com o Auth.
      debugPrint('Não foi possível ler usuarios/$uid: $e');
    }
  }

  Future<void> signIn(String email, String senha) async {
    final auth = _exigirAuth();
    try {
      await auth.signInWithEmailAndPassword(
          email: email.trim(), password: senha);
    } catch (e) {
      throw AuthException(message(e));
    }
  }

  /// Cria a conta no Auth e grava `usuarios/{uid}` com perfil MORADOR.
  Future<void> register(String email, String senha) async {
    final auth = _exigirAuth();
    final emailLimpo = email.trim();
    final nomeInicial = emailLimpo.split('@').first;
    try {
      final cred = await auth.createUserWithEmailAndPassword(
          email: emailLimpo, password: senha);
      final u = cred.user;
      if (u == null) return;
      await u.updateDisplayName(nomeInicial);
      await u.reload();
      _user = auth.currentUser;
      notifyListeners();
      // Usa o e-mail como o Firebase guardou (minúsculas): a regra do
      // Firestore exige que seja igual ao do login.
      await _criarDocumentoUsuario(u.uid, u.email ?? emailLimpo, nomeInicial);
    } catch (e) {
      throw AuthException(message(e));
    }
  }

  /// Cria `usuarios/{uid}` só se ainda não existir.
  ///
  /// No cadastro, o `register` e o `_carregarUsuario` (disparado pelo login
  /// automático) chamam este método quase ao mesmo tempo. A transação lê e
  /// grava de uma vez: se as duas correrem juntas, o Firestore repete a
  /// segunda, que encontra o documento e não grava de novo. Sem isso, a
  /// segunda gravação virava uma alteração de `criadoEm`, recusada pelas
  /// regras.
  Future<void> _criarDocumentoUsuario(
      String uid, String email, String nome) async {
    final novo = Usuario(
      id: uid,
      email: email,
      nome: nome,
      criadoEm: DateTime.now(),
      preferenciaNotificacao: const PreferenciaNotificacao(),
    );
    final ref = _usuarios.doc(uid);
    try {
      final existente =
          await FirebaseFirestore.instance.runTransaction((tx) async {
        final doc = await tx.get(ref);
        if (doc.exists) return Usuario.fromFirestore(doc);
        tx.set(ref, novo.toFirestore());
        return null;
      });
      if (_user?.uid != uid) return;
      _usuario = existente ?? novo;
      notifyListeners();
    } catch (e) {
      // A conta continua criada no Auth; o documento é criado no próximo
      // login (_carregarUsuario).
      debugPrint('Não foi possível gravar usuarios/$uid: $e');
    }
  }

  /// Envia o e-mail do Firebase com o link para criar uma nova senha.
  Future<void> resetPassword(String email) async {
    final auth = _exigirAuth();
    try {
      await auth.setLanguageCode('pt');
      await auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw AuthException(message(e));
    }
  }

  Future<void> signOut() async {
    final auth = _exigirAuth();
    try {
      await auth.signOut();
      _usuario = null;
    } catch (e) {
      throw AuthException(message(e));
    }
  }

  /// Altera o nome (na conta e no Firestore) e a preferência de notificação
  /// (só no Firestore).
  Future<void> updateProfile({String? nome, bool? notificacoes}) async {
    final auth = _exigirAuth();
    final u = auth.currentUser;
    if (u == null) return;
    try {
      if (nome != null) {
        await u.updateDisplayName(nome);
        await u.reload();
        _user = auth.currentUser;
        notifyListeners();
      }
      final preferencia = notificacoes == null
          ? null
          : PreferenciaNotificacao(
              ativa: notificacoes,
              raioKm: _usuario?.preferenciaNotificacao?.raioKm ?? 2,
            );
      final dados = <String, dynamic>{
        'nome': ?nome,
        if (preferencia != null) 'preferenciaNotificacao': preferencia.toMap(),
      };
      if (dados.isEmpty) return;
      await _usuarios.doc(u.uid).update(dados);
      final atual = _usuario;
      if (atual != null) {
        _usuario =
            atual.copyWith(nome: nome, preferenciaNotificacao: preferencia);
      }
      notifyListeners();
    } catch (e) {
      throw AuthException(message(e));
    }
  }

  /// Traduz os erros do Firebase para mensagens em português.
  static String message(Object e) {
    if (e is AuthException) return e.message;
    if (e is FirebaseAuthException) {
      return switch (e.code) {
        'invalid-email' => 'E-mail inválido.',
        'missing-email' => 'Informe o e-mail.',
        'user-disabled' => 'Esta conta foi desativada.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' ||
        'INVALID_LOGIN_CREDENTIALS' =>
          'E-mail ou senha incorretos.',
        'email-already-in-use' => 'Este e-mail já está cadastrado.',
        'weak-password' =>
          'Senha fraca. Use pelo menos 8 caracteres, com letras e números.',
        'network-request-failed' =>
          'Sem conexão com a internet. Verifique e tente novamente.',
        'too-many-requests' =>
          'Muitas tentativas. Aguarde alguns minutos e tente de novo.',
        'requires-recent-login' =>
          'Por segurança, saia e entre de novo para fazer esta alteração.',
        'operation-not-allowed' =>
          'Login por e-mail e senha não está ativado no Firebase.',
        _ => 'Não foi possível concluir. Tente novamente.',
      };
    }
    if (e is FirebaseException) {
      return switch (e.code) {
        'permission-denied' => 'Você não tem permissão para salvar estes dados.',
        'unavailable' =>
          'Sem conexão com a internet. Verifique e tente novamente.',
        _ => 'Não foi possível salvar. Tente novamente.',
      };
    }
    return 'Ocorreu um erro. Tente novamente.';
  }
}
