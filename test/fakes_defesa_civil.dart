import 'package:enchente_alerta/models/models.dart';
import 'package:enchente_alerta/services/abrigos_service.dart';
import 'package:enchente_alerta/services/alertas_service.dart';
import 'package:enchente_alerta/services/defesa_civil_service.dart';

/// Versões falsas dos serviços da Defesa Civil: guardam tudo na memória,
/// sem Firebase, e registram o que as telas pediram.

class AbrigosFalsos extends AbrigosService {
  final salvos = <Abrigo>[];
  final excluidos = <String>[];

  @override
  void iniciar() {}

  @override
  Future<void> salvar(Abrigo abrigo) async {
    salvos.add(abrigo);
    final id = abrigo.id.isEmpty ? 'novo${salvos.length}' : abrigo.id;
    cadastrados.value = [
      for (final a in cadastrados.value)
        if (a.id != id) a,
      Abrigo(
        id: id,
        nome: abrigo.nome,
        bairro: abrigo.bairro,
        localizacao: abrigo.localizacao,
        capacidade: abrigo.capacidade,
        vagasDisponiveis: abrigo.vagasDisponiveis,
        ativo: abrigo.ativo,
      ),
    ];
  }

  @override
  Future<void> excluir(Abrigo abrigo) async {
    excluidos.add(abrigo.id);
    cadastrados.value = [
      for (final a in cadastrados.value)
        if (a.id != abrigo.id) a,
    ];
  }
}

class AlertasFalsos extends AlertasService {
  final salvos = <Alerta>[];
  final encerrados = <String>[];

  @override
  void iniciar() {}

  @override
  Future<void> salvar(Alerta alerta) async {
    salvos.add(alerta);
    final id = alerta.id.isEmpty ? 'al${salvos.length}' : alerta.id;
    alertas.value = [
      Alerta(
        id: id,
        titulo: alerta.titulo,
        descricao: alerta.descricao,
        nivel: alerta.nivel,
        origem: alerta.origem,
        emitidoEm: alerta.emitidoEm,
        expiraEm: alerta.expiraEm,
      ),
      for (final a in alertas.value)
        if (a.id != id) a,
    ];
  }

  @override
  Future<void> encerrar(Alerta alerta) async => encerrados.add(alerta.id);
}

class DefesaCivilFalsa extends DefesaCivilService {
  final resolvidos = <String>[];
  final mantidos = <String>[];
  final excluidos = <String>[];

  @override
  void iniciar() {}

  @override
  void parar() {}

  void _tirar(String id) => pendentes.value = [
        for (final g in pendentes.value)
          if (g.ocorrenciaId != id) g,
      ];

  @override
  Future<void> resolverAviso(String avisoId,
      {List<Denuncia> denuncias = const []}) async {
    resolvidos.add(avisoId);
    _tirar(avisoId);
  }

  @override
  Future<void> manterAviso(String avisoId, List<Denuncia> denuncias) async {
    mantidos.add(avisoId);
    _tirar(avisoId);
  }

  @override
  Future<void> excluirAviso(String avisoId, List<Denuncia> denuncias) async {
    excluidos.add(avisoId);
    _tirar(avisoId);
  }
}
