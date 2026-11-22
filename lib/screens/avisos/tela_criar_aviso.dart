import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../config.dart';
import '../../models/destino.dart';
import '../../models/models.dart';
import '../../services/localizacao_service.dart';
import '../../services/perigos_service.dart';
import '../../services/rotas_service.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/botao_gravidade.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../../widgets/widgets_conta.dart';

/// Abre a tela "Criar aviso". Devolve true quando o aviso foi criado.
Future<bool?> abrirCriarAviso(BuildContext context) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const TelaCriarAviso()),
  );
}

/// Tela "05 Criar aviso" do protótipo: gravidade, endereço e nível da água.
///
/// O endereço começa preenchido com o da posição atual. Se a pessoa digitar
/// outro, escolhe uma das sugestões para o aviso cair no lugar certo do mapa.
/// A gravação (ocorrência + autor separado, RNF07) fica no PerigosService.
class TelaCriarAviso extends StatefulWidget {
  const TelaCriarAviso({super.key});

  @override
  State<TelaCriarAviso> createState() => _TelaCriarAvisoState();
}

class _TelaCriarAvisoState extends State<TelaCriarAviso> {
  static const _espera = Duration(milliseconds: 450);
  static const _minimoLetras = 3;

  final _form = GlobalKey<FormState>();
  final _endereco = TextEditingController();
  final _nivel = TextEditingController();
  final _descricao = TextEditingController();

  Gravidade? _gravidade;

  /// Ponto do aviso no mapa: o da posição atual ou o da sugestão escolhida.
  /// Fica null quando a pessoa digita um endereço e não escolhe sugestão.
  LatLng? _local;

  List<Destino> _sugestoes = const [];
  Timer? _timer;
  int _consulta = 0;

  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _preencherComPosicaoAtual();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _endereco.dispose();
    _nivel.dispose();
    _descricao.dispose();
    super.dispose();
  }

  /// A posição só vale se for do GPS de verdade (ou do modo de teste).
  Future<LatLng?> _posicaoConfiavel() async {
    try {
      final posicao = await LocalizacaoService.instance.atual();
      if (posicao.deTeste && !Config.usarLocalizacaoDeTeste) return null;
      return posicao.ponto;
    } catch (_) {
      return null;
    }
  }

  Future<void> _preencherComPosicaoAtual() async {
    final ponto = await _posicaoConfiavel();
    if (ponto == null) return;
    final texto = await RotasService.instance.enderecoDe(ponto);
    // Não apaga o que a pessoa já começou a digitar.
    if (!mounted || texto == null || _endereco.text.isNotEmpty) return;
    setState(() {
      _endereco.text = texto;
      _local = ponto;
    });
  }

  void _aoDigitarEndereco(String texto) {
    _timer?.cancel();
    _consulta++;
    setState(() {
      _local = null;
      if (texto.trim().length < _minimoLetras) _sugestoes = const [];
    });
    if (texto.trim().length < _minimoLetras) return;
    _timer = Timer(_espera, () => _buscar(texto));
  }

  Future<void> _buscar(String texto) async {
    final consulta = ++_consulta;
    List<Destino> achados = const [];
    try {
      achados = await RotasService.instance.buscarEnderecos(
        texto,
        perto: LocalizacaoService.instance.posicao.value?.ponto,
      );
    } on RotaException {
      // Sem chave ou sem internet: segue sem sugestões.
    }
    if (!mounted || consulta != _consulta) return;
    setState(() => _sugestoes = achados);
  }

  void _escolher(Destino d) {
    _timer?.cancel();
    _consulta++;
    FocusScope.of(context).unfocus();
    setState(() {
      _endereco.text = d.detalhe ?? d.nome;
      _local = d.posicao;
      _sugestoes = const [];
    });
  }

  /// Ponto do aviso. Sem sugestão escolhida, tenta achar o endereço; sem
  /// busca disponível (sem chave do OpenRouteService), usa a posição atual.
  Future<LatLng> _resolverLocal() async {
    final escolhido = _local;
    if (escolhido != null) return escolhido;
    if (RotasService.instance.buscaDisponivel) {
      try {
        final achados = await RotasService.instance.buscarEnderecos(
          _endereco.text,
          perto: LocalizacaoService.instance.posicao.value?.ponto,
        );
        if (achados.isNotEmpty) return achados.first.posicao;
      } on RotaException catch (e) {
        throw PerigoException(e.mensagem);
      }
      throw PerigoException(
          'Endereço não encontrado. Escolha uma das sugestões da lista.');
    }
    final ponto = await _posicaoConfiavel();
    if (ponto != null) return ponto;
    throw PerigoException(
        'Não conseguimos localizar o endereço. Ative o GPS e tente de novo.');
  }

  Future<void> _criar() async {
    setState(() => _erro = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _enviando = true);
    try {
      final local = await _resolverLocal();
      await PerigosService.instance.reportar(
        tipo: TipoOcorrencia.alagamento,
        gravidade: _gravidade!,
        local: local,
        endereco: _endereco.text.trim(),
        nivelAguaCm: int.parse(_nivel.text),
        descricao: _descricao.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PerigoException catch (e) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _erro = e.mensagem;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final rotulo = TextStyle(
      color: cores.primary,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );

    return ScaffoldComAbas(
      abaAtiva: 1,
      appBar: const AppBarTela(
        titulo: 'Criar aviso',
        ajuda: TextosAjuda.criarAviso,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Criar aviso',
                style: TextStyle(
                  color: cores.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Avise sua vizinhança sobre um ponto de alagamento em tempo '
                'real.',
                style: TextStyle(color: cores.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Text('Gravidade do alagamento', style: rotulo),
              const SizedBox(height: 8),
              FormField<Gravidade>(
                validator: (_) =>
                    _gravidade == null ? 'Escolha a gravidade.' : null,
                builder: (campo) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (final g in Gravidade.values) ...[
                          if (g != Gravidade.values.first)
                            const SizedBox(width: 10),
                          Expanded(
                            child: BotaoGravidade(
                              gravidade: g,
                              selecionada: _gravidade == g,
                              aoTocar: () {
                                setState(() => _gravidade = g);
                                campo.didChange(g);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (campo.errorText case final erro?)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 12),
                        child: Text(
                          erro,
                          style: TextStyle(color: cores.error, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Endereço', style: rotulo),
              const SizedBox(height: 6),
              TextFormField(
                controller: _endereco,
                textCapitalization: TextCapitalization.words,
                maxLength: 200,
                onChanged: _aoDigitarEndereco,
                decoration: InputDecoration(
                  hintText: 'Rua, número, bairro',
                  hintStyle: TextStyle(color: cores.onSurfaceVariant),
                  counterText: '',
                  helperText: _local != null && _sugestoes.isEmpty
                      ? 'Local confirmado no mapa'
                      : null,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o endereço.'
                    : null,
              ),
              for (final d in _sugestoes)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(d.nome),
                  subtitle: d.detalhe == null ? null : Text(d.detalhe!),
                  onTap: () => _escolher(d),
                ),
              const SizedBox(height: 16),
              Text('Nível da água (cm)', style: rotulo),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nivel,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Ex.: 40',
                  hintStyle: TextStyle(color: cores.onSurfaceVariant),
                ),
                validator: (v) {
                  final cm = int.tryParse(v ?? '');
                  if (cm == null) return 'Informe o nível da água em cm.';
                  if (cm > 500) return 'Use um valor de 0 a 500 cm.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Descrição (opcional)', style: rotulo),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descricao,
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ex.: carro não passa, água subindo',
                  hintStyle: TextStyle(color: cores.onSurfaceVariant),
                ),
              ),
              if (_erro case final erro?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(erro, style: TextStyle(color: cores.error)),
                ),
              const SizedBox(height: 4),
              PrimaryButton(
                text: 'Criar',
                onPressed: _criar,
                loading: _enviando,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
