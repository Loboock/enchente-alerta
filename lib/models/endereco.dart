import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'conversores.dart';

/// Subcoleção `usuarios/{uid}/enderecos/{enderecoId}`.
class Endereco {
  final String id;
  final String logradouro;
  final String bairro;
  final String cidade;
  final LatLng localizacao;
  final bool padrao;

  const Endereco({
    required this.id,
    required this.logradouro,
    required this.bairro,
    required this.cidade,
    required this.localizacao,
    this.padrao = false,
  });

  double get latitude => localizacao.latitude;
  double get longitude => localizacao.longitude;

  factory Endereco.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Endereco.fromMap(doc.id, doc.data()!);

  factory Endereco.fromMap(String id, Map<String, dynamic> d) => Endereco(
        id: id,
        logradouro: d['logradouro'] as String,
        bairro: d['bairro'] as String,
        cidade: d['cidade'] as String,
        localizacao: lerPonto(d['localizacao']),
        padrao: d['padrao'] as bool? ?? false,
      );

  Map<String, dynamic> toFirestore() => {
        'logradouro': logradouro,
        'bairro': bairro,
        'cidade': cidade,
        'localizacao': gravarPonto(localizacao),
        'padrao': padrao,
      };
}
