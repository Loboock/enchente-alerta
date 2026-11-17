import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'conversores.dart';

/// Coleção `abrigos/{abrigoId}`. Só a Defesa Civil cria, edita e exclui.
class Abrigo {
  final String id;
  final String nome;
  final String bairro;
  final LatLng localizacao;
  final int capacidade;
  final int vagasDisponiveis;
  final bool ativo;
  final String? atualizadoPor;
  final DateTime? atualizadoEm;

  const Abrigo({
    required this.id,
    required this.nome,
    required this.bairro,
    required this.localizacao,
    required this.capacidade,
    required this.vagasDisponiveis,
    this.ativo = true,
    this.atualizadoPor,
    this.atualizadoEm,
  });

  double get latitude => localizacao.latitude;
  double get longitude => localizacao.longitude;

  bool get estaDisponivel => ativo && vagasDisponiveis > 0;

  /// Distância em metros até um ponto (ex.: a posição do usuário).
  double distanciaAte(LatLng ponto) =>
      const Distance().as(LengthUnit.Meter, localizacao, ponto);

  factory Abrigo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Abrigo.fromMap(doc.id, doc.data()!);

  factory Abrigo.fromMap(String id, Map<String, dynamic> d) => Abrigo(
        id: id,
        nome: d['nome'] as String,
        bairro: d['bairro'] as String? ?? '',
        localizacao: lerPonto(d['localizacao']),
        capacidade: lerInt(d['capacidade']),
        vagasDisponiveis: lerInt(d['vagasDisponiveis']),
        ativo: d['ativo'] as bool? ?? true,
        atualizadoPor: d['atualizadoPor'] as String?,
        atualizadoEm: lerDataOpcional(d['atualizadoEm']),
      );

  Map<String, dynamic> toFirestore() => {
        'nome': nome,
        'bairro': bairro,
        'localizacao': gravarPonto(localizacao),
        'capacidade': capacidade,
        'vagasDisponiveis': vagasDisponiveis,
        'ativo': ativo,
        if (atualizadoPor != null) 'atualizadoPor': atualizadoPor,
        if (atualizadoEm != null)
          'atualizadoEm': Timestamp.fromDate(atualizadoEm!),
      };
}
