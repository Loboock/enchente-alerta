import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'conversores.dart';
import 'enums.dart';

/// Coleção `ocorrencias/{ocorrenciaId}`: alagamento ou via obstruída
/// registrado pela comunidade.
///
/// O autor (`autorId` no diagrama) NÃO fica neste documento, e sim em
/// `autoresOcorrencias/{ocorrenciaId}`, para manter o anonimato (RNF07).
class Ocorrencia {
  final String id;
  final TipoOcorrencia tipo;
  final Gravidade gravidade;
  final StatusOcorrencia status;
  final String endereco;
  final LatLng localizacao;
  final int nivelAguaCm;
  final String? descricao;
  final String? imagemUrl;
  final String? areaRiscoId;
  final DateTime criadaEm;
  final DateTime expiraEm;

  const Ocorrencia({
    required this.id,
    required this.tipo,
    required this.gravidade,
    this.status = StatusOcorrencia.ativa,
    required this.endereco,
    required this.localizacao,
    required this.nivelAguaCm,
    this.descricao,
    this.imagemUrl,
    this.areaRiscoId,
    required this.criadaEm,
    required this.expiraEm,
  });

  double get latitude => localizacao.latitude;
  double get longitude => localizacao.longitude;

  /// Sem Cloud Functions, o app considera expirada a ocorrência com
  /// `expiraEm` no passado, mesmo que o status ainda seja ATIVA.
  bool estaAtiva([DateTime? agora]) =>
      status == StatusOcorrencia.ativa &&
      expiraEm.isAfter(agora ?? DateTime.now());

  factory Ocorrencia.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      Ocorrencia.fromMap(doc.id, doc.data()!);

  factory Ocorrencia.fromMap(String id, Map<String, dynamic> d) => Ocorrencia(
        id: id,
        tipo: enumPorCodigo(TipoOcorrencia.values, d['tipo']),
        gravidade: enumPorCodigo(Gravidade.values, d['gravidade']),
        status: enumPorCodigo(StatusOcorrencia.values, d['status']),
        endereco: d['endereco'] as String,
        localizacao: lerPonto(d['localizacao']),
        nivelAguaCm: lerInt(d['nivelAguaCm']),
        descricao: d['descricao'] as String?,
        imagemUrl: d['imagemUrl'] as String?,
        areaRiscoId: d['areaRiscoId'] as String?,
        criadaEm: lerData(d['criadaEm']),
        expiraEm: lerData(d['expiraEm']),
      );

  Map<String, dynamic> toFirestore() => {
        'tipo': tipo.codigo,
        'gravidade': gravidade.codigo,
        'status': status.codigo,
        'endereco': endereco,
        'localizacao': gravarPonto(localizacao),
        'nivelAguaCm': nivelAguaCm,
        if (descricao != null) 'descricao': descricao,
        if (imagemUrl != null) 'imagemUrl': imagemUrl,
        if (areaRiscoId != null) 'areaRiscoId': areaRiscoId,
        'criadaEm': Timestamp.fromDate(criadaEm),
        'expiraEm': Timestamp.fromDate(expiraEm),
      };

  Ocorrencia copyWith({StatusOcorrencia? status, String? id}) => Ocorrencia(
        id: id ?? this.id,
        tipo: tipo,
        gravidade: gravidade,
        status: status ?? this.status,
        endereco: endereco,
        localizacao: localizacao,
        nivelAguaCm: nivelAguaCm,
        descricao: descricao,
        imagemUrl: imagemUrl,
        areaRiscoId: areaRiscoId,
        criadaEm: criadaEm,
        expiraEm: expiraEm,
      );
}
