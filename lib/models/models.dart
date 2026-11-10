/// Classes de domínio do EnchenteAlerta (docs/diagrama-de-classes.md),
/// com o mapeamento para o Firestore (docs/modelagem-firestore.md).
///
/// Uso: `import 'package:enchente_alerta/models/models.dart';`
///
/// `PacoteOffline` não está aqui: ele não vai para o Firestore e será criado
/// junto com o modo offline (tarefa 8).
library;

export 'abrigo.dart';
export 'alerta.dart';
export 'area_risco.dart';
export 'denuncia.dart';
export 'endereco.dart';
export 'enums.dart';
export 'guia_orientacao.dart';
export 'notificacao.dart';
export 'ocorrencia.dart';
export 'rota_fuga.dart';
export 'usuario.dart';
