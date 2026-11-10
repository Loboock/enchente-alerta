import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversores.dart';
import 'enums.dart';

/// Coleção `usuarios/{uid}`. O id do documento é o uid do Firebase Auth.
///
/// Cadastrar, entrar, sair e recuperar senha (métodos do diagrama) ficam no
/// serviço de autenticação, não no modelo, porque dependem do Firebase Auth.
class Usuario {
  final String id;
  final String email;
  final String nome;
  final PerfilUsuario perfil;
  final DateTime criadoEm;
  final PreferenciaNotificacao? preferenciaNotificacao;

  const Usuario({
    required this.id,
    required this.email,
    required this.nome,
    this.perfil = PerfilUsuario.morador,
    required this.criadoEm,
    this.preferenciaNotificacao,
  });

  bool get ehDefesaCivil => perfil == PerfilUsuario.defesaCivil;

  factory Usuario.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Usuario.fromMap(doc.id, doc.data()!);

  factory Usuario.fromMap(String id, Map<String, dynamic> d) => Usuario(
        id: id,
        email: d['email'] as String,
        nome: d['nome'] as String? ?? '',
        perfil: enumPorCodigo(PerfilUsuario.values, d['perfil']),
        criadoEm: lerData(d['criadoEm']),
        preferenciaNotificacao: d['preferenciaNotificacao'] == null
            ? null
            : PreferenciaNotificacao.fromMap(
                Map<String, dynamic>.from(d['preferenciaNotificacao'] as Map),
              ),
      );

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'nome': nome,
        'perfil': perfil.codigo,
        'criadoEm': Timestamp.fromDate(criadoEm),
        if (preferenciaNotificacao != null)
          'preferenciaNotificacao': preferenciaNotificacao!.toMap(),
      };

  Usuario copyWith({
    String? nome,
    PreferenciaNotificacao? preferenciaNotificacao,
  }) =>
      Usuario(
        id: id,
        email: email,
        nome: nome ?? this.nome,
        perfil: perfil,
        criadoEm: criadoEm,
        preferenciaNotificacao:
            preferenciaNotificacao ?? this.preferenciaNotificacao,
      );
}

/// Fica dentro do documento do usuário (composição 1 para 0..1).
class PreferenciaNotificacao {
  final bool ativa;
  final double raioKm;

  const PreferenciaNotificacao({this.ativa = true, this.raioKm = 2});

  factory PreferenciaNotificacao.fromMap(Map<String, dynamic> d) =>
      PreferenciaNotificacao(
        ativa: d['ativa'] as bool? ?? true,
        raioKm: d['raioKm'] == null ? 2 : lerDouble(d['raioKm']),
      );

  Map<String, dynamic> toMap() => {'ativa': ativa, 'raioKm': raioKm};
}
