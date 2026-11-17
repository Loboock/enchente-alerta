import 'package:enchente_alerta/data/dados_provisorios.dart';
import 'package:enchente_alerta/models/destino.dart';
import 'package:enchente_alerta/models/perigo.dart';
import 'package:enchente_alerta/models/rota_calculada.dart';
import 'package:enchente_alerta/services/localizacao_service.dart';
import 'package:enchente_alerta/services/rotas_service.dart';
import 'package:latlong2/latlong.dart';

/// GPS falso: fica parado na Farolândia.
class LocalizacaoFalsa extends LocalizacaoService {
  @override
  Future<void> iniciar() async {
    posicao.value ??= const PosicaoUsuario(ponto: usuarioProvisorio);
  }

  @override
  Future<PosicaoUsuario> atual() async {
    await iniciar();
    return posicao.value!;
  }
}

/// Serviço de rotas falso: devolve sempre uma rota de 950 m sem internet.
class RotasFalsas extends RotasService {
  RotasFalsas() : super(chave: '');

  final pedidos = <({ModoTransporte modo, List<Perigo> perigos})>[];

  @override
  bool get buscaDisponivel => true;

  @override
  Future<RotaCalculada> calcular({
    required LatLng origem,
    required LatLng destino,
    required ModoTransporte modo,
    List<Perigo> perigos = const [],
  }) async {
    pedidos.add((modo: modo, perigos: perigos));
    return RotaCalculada(
      modo: modo,
      pontos: [origem, destino],
      distanciaMetros: 950,
      duracaoSeg: modo == ModoTransporte.carro ? 240 : 780,
      passos: const [
        PassoRota(
          tipo: 11,
          instrucao: 'Siga para o norte',
          via: '',
          distanciaMetros: 950,
          duracaoSeg: 240,
          inicio: 0,
          fim: 1,
        ),
        PassoRota(
          tipo: 10,
          instrucao: 'Você chegou',
          via: '',
          distanciaMetros: 0,
          duracaoSeg: 0,
          inicio: 1,
          fim: 1,
        ),
      ],
    );
  }

  /// "xyz" não acha nada; qualquer outro texto acha a "Rua Teste".
  @override
  Future<List<Destino>> buscarEnderecos(String texto, {LatLng? perto}) async {
    if (texto.contains('xyz')) return const [];
    return [
      Destino(
        nome: 'Rua Teste',
        detalhe: 'Rua Teste, Farolândia, Aracaju',
        posicao: const Distance().offset(usuarioProvisorio, 900, 330),
      ),
    ];
  }

  @override
  Future<String?> enderecoDe(LatLng ponto) async => null;
}
