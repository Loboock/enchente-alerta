// Versão de teste: login falso em memória (sem Firebase).
// Usuário pronto: teste@gmail.com / 12345678
import 'package:flutter/material.dart';
 
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
 
class AppUser {
  String email, senha, nome, endereco = '';
  bool notificacoes = true;
  AppUser(this.email, this.senha, this.nome);
}
 
class AuthService extends ChangeNotifier {
  AuthService._() {
    _users['teste@gmail.com'] = AppUser('teste@gmail.com', '12345678', 'Teste');
  }
  static final instance = AuthService._();
 
  final Map<String, AppUser> _users = {};
  AppUser? _current;
  AppUser? get user => _current;
  String? savedEmail; // "Salvar login"
 
  String _k(String e) => e.trim().toLowerCase();
 
  Future<void> signIn(String email, String senha) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final u = _users[_k(email)];
    if (u == null || u.senha != senha) {
      throw AuthException('E-mail ou senha incorretos.');
    }
    _current = u;
    notifyListeners();
  }
 
  Future<void> register(String email, String senha) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_users.containsKey(_k(email))) {
      throw AuthException('Este e-mail já está cadastrado.');
    }
    final u = AppUser(_k(email), senha, _k(email).split('@').first);
    _users[u.email] = u;
    _current = u;
    notifyListeners();
  }
 
  Future<void> resetPassword(String email, String novaSenha) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final u = _users[_k(email)];
    if (u == null) throw AuthException('E-mail não encontrado.');
    u.senha = novaSenha;
  }
 
  void signOut() {
    _current = null;
    notifyListeners();
  }
 
  void updateProfile({String? nome, String? endereco, bool? notificacoes}) {
    final u = _current;
    if (u == null) return;
    if (nome != null) u.nome = nome;
    if (endereco != null) u.endereco = endereco;
    if (notificacoes != null) u.notificacoes = notificacoes;
    notifyListeners();
  }
 
  static String message(Object e) =>
      e is AuthException ? e.message : 'Ocorreu um erro. Tente novamente.';
}
