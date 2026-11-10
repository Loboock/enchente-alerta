/// Enumerações do diagrama de classes (docs/diagrama-de-classes.md).
///
/// No Dart os valores seguem o padrão da linguagem (`grave`), mas cada um
/// guarda o [codigo] gravado no Firestore (`"GRAVE"`), como definido em
/// docs/modelagem-firestore.md. O [rotulo] é o texto mostrado na tela.
library;

/// Contrato comum das enumerações gravadas no Firestore como texto.
abstract interface class EnumFirestore {
  String get codigo;
  String get rotulo;
}

/// Converte o texto gravado no Firestore de volta para o valor da enumeração.
///
/// Lança [FormatException] se o texto não corresponder a nenhum valor, para
/// que um dado inválido no banco não passe despercebido.
T enumPorCodigo<T extends EnumFirestore>(List<T> valores, Object? codigo) {
  for (final valor in valores) {
    if (valor.codigo == codigo) return valor;
  }
  throw FormatException('Código "$codigo" inválido para ${T.toString()}');
}

enum PerfilUsuario implements EnumFirestore {
  morador('MORADOR', 'Morador'),
  defesaCivil('DEFESA_CIVIL', 'Defesa Civil');

  const PerfilUsuario(this.codigo, this.rotulo);
  @override
  final String codigo;
  @override
  final String rotulo;
}

enum TipoOcorrencia implements EnumFirestore {
  alagamento('ALAGAMENTO', 'Alagamento'),
  viaObstruida('VIA_OBSTRUIDA', 'Via obstruída');

  const TipoOcorrencia(this.codigo, this.rotulo);
  @override
  final String codigo;
  @override
  final String rotulo;
}

/// Os 3 níveis do protótipo de alta fidelidade.
enum Gravidade implements EnumFirestore {
  leve('LEVE', 'Leve'),
  moderado('MODERADO', 'Moderado'),
  grave('GRAVE', 'Grave');

  const Gravidade(this.codigo, this.rotulo);
  @override
  final String codigo;
  @override
  final String rotulo;
}

enum StatusOcorrencia implements EnumFirestore {
  ativa('ATIVA', 'Ativa'),
  resolvida('RESOLVIDA', 'Resolvida'),
  expirada('EXPIRADA', 'Expirada');

  const StatusOcorrencia(this.codigo, this.rotulo);
  @override
  final String codigo;
  @override
  final String rotulo;
}

/// Os 4 motivos da tela "Reportar aviso" do protótipo.
enum MotivoDenuncia implements EnumFirestore {
  informacaoIncorreta('INFORMACAO_INCORRETA', 'Informação incorreta'),
  aguaBaixou('AGUA_BAIXOU', 'A água já baixou'),
  localizacaoErrada('LOCALIZACAO_ERRADA', 'Localização errada'),
  spamOuAbuso('SPAM_OU_ABUSO', 'Spam ou abuso');

  const MotivoDenuncia(this.codigo, this.rotulo);
  @override
  final String codigo;
  @override
  final String rotulo;
}

enum OrigemAlerta implements EnumFirestore {
  meteorologica('METEOROLOGICA', 'Meteorológica'),
  comunidade('COMUNIDADE', 'Comunidade');

  const OrigemAlerta(this.codigo, this.rotulo);
  @override
  final String codigo;
  @override
  final String rotulo;
}

enum FaseGuia implements EnumFirestore {
  antes('ANTES', 'Antes'),
  durante('DURANTE', 'Durante'),
  evacuacao('EVACUACAO', 'Evacuação'),
  depois('DEPOIS', 'Depois'),
  emergencia('EMERGENCIA', 'Emergência');

  const FaseGuia(this.codigo, this.rotulo);
  @override
  final String codigo;
  @override
  final String rotulo;
}
