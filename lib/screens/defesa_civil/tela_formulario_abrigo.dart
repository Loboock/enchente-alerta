import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../models/destino.dart';
import '../../models/models.dart';
import '../../services/abrigos_service.dart';
import '../../services/erro_servico.dart';
import '../../services/localizacao_service.dart';
import '../../services/rotas_service.dart';
import '../../utils/formatacao.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/app_bar_tela.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../../widgets/widgets_conta.dart';

/// Abre o formulário para cadastrar (sem [abrigo]) ou editar um abrigo.
/// Devolve true quando salvou.
Future<bool?> abrirFormularioAbrigo(BuildContext context, {Abrigo? abrigo}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => TelaFormularioAbrigo(abrigo: abrigo)),
  );
}

class TelaFormularioAbrigo extends StatefulWidget {
  const TelaFormularioAbrigo({super.key, this.abrigo});

  final Abrigo? abrigo;

  @override
  State<TelaFormularioAbrigo> createState() => _TelaFormularioAbrigoState();
}

class _TelaFormularioAbrigoState extends State<TelaFormularioAbrigo> {
  static const _espera = Duration(milliseconds: 450);

  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.abrigo?.nome);
  late final _bairro = TextEditingController(text: widget.abrigo?.bairro);
  late final _capacidade = TextEditingController(
    text: widget.abrigo?.capacidade.toString(),
  );
  late final _vagas = TextEditingController(
    text: widget.abrigo?.vagasDisponiveis.toString(),
  );
  final _endereco = TextEditingController();
  late bool _ativo = widget.abrigo?.ativo ?? true;

  /// Local do abrigo no mapa (obrigatório).
  late LatLng? _local = widget.abrigo?.localizacao;
  String? _descricaoLocal;

  List<Destino> _sugestoes = const [];
  Timer? _timer;
  int _consulta = 0;
  bool _salvando = false;
  String? _erro;
  String? _erroLocal;

  bool get _editando => widget.abrigo != null;

  @override
  void initState() {
    super.initState();
    if (_local != null) _descricaoLocal = 'Local atual do abrigo mantido';
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_nome, _bairro, _capacidade, _vagas, _endereco]) {
      c.dispose();
    }
    super.dispose();
  }

  void _aoDigitarEndereco(String texto) {
    _timer?.cancel();
    _consulta++;
    if (texto.trim().length < 3) {
      setState(() => _sugestoes = const []);
      return;
    }
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
    } on RotaException catch (e) {
      if (mounted && consulta == _consulta) {
        setState(() => _erroLocal = e.mensagem);
      }
      return;
    }
    if (!mounted || consulta != _consulta) return;
    setState(() {
      _sugestoes = achados;
      _erroLocal = achados.isEmpty ? 'Nenhum endereço encontrado.' : null;
    });
  }

  void _escolher(Destino d) {
    _timer?.cancel();
    _consulta++;
    FocusScope.of(context).unfocus();
    setState(() {
      _local = d.posicao;
      _descricaoLocal = d.detalhe ?? d.nome;
      _endereco.text = d.detalhe ?? d.nome;
      _sugestoes = const [];
      _erroLocal = null;
    });
  }

  Future<void> _usarMinhaPosicao() async {
    try {
      final posicao = await LocalizacaoService.instance.atual();
      if (!mounted) return;
      setState(() {
        _local = posicao.ponto;
        _descricaoLocal = posicao.deTeste
            ? 'Posição de teste (sem GPS)'
            : 'Sua posição atual';
        _erroLocal = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _erroLocal = 'Não foi possível obter a sua posição.');
      }
    }
  }

  String? _validarNumero(String? v, {required String campo}) {
    final n = int.tryParse(v ?? '');
    if (n == null) return 'Informe $campo.';
    if (n > 100000) return 'Valor alto demais.';
    return null;
  }

  Future<void> _salvar() async {
    setState(() => _erro = null);
    final formOk = _form.currentState?.validate() ?? false;
    final local = _local;
    if (local == null) {
      setState(() => _erroLocal = 'Escolha o local do abrigo.');
    }
    if (!formOk || local == null) return;

    setState(() => _salvando = true);
    try {
      await AbrigosService.instance.salvar(
        Abrigo(
          id: widget.abrigo?.id ?? '',
          nome: _nome.text.trim(),
          bairro: _bairro.text.trim(),
          localizacao: local,
          capacidade: int.parse(_capacidade.text),
          vagasDisponiveis: int.parse(_vagas.text),
          ativo: _ativo,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ServicoException catch (e) {
      if (mounted) {
        setState(() {
          _salvando = false;
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
    final local = _local;

    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: AppBarTela(
        voltar: true,
        titulo: _editando ? 'Editar abrigo' : 'Novo abrigo',
        ajuda: TextosAjuda.formularioAbrigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nome', style: rotulo),
              const SizedBox(height: 6),
              TextFormField(
                key: const Key('campo-nome-abrigo'),
                controller: _nome,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ex.: Escola Estadual X',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o nome do abrigo.'
                    : null,
              ),
              Text('Bairro', style: rotulo),
              const SizedBox(height: 6),
              TextFormField(
                key: const Key('campo-bairro-abrigo'),
                controller: _bairro,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Ex.: Farolândia'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o bairro.'
                    : null,
              ),
              Text('Local no mapa', style: rotulo),
              const SizedBox(height: 6),
              TextField(
                controller: _endereco,
                onChanged: _aoDigitarEndereco,
                decoration: const InputDecoration(
                  hintText: 'Buscar endereço do abrigo',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              for (final d in _sugestoes)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(d.nome),
                  subtitle: d.detalhe == null ? null : Text(d.detalhe!),
                  onTap: () => _escolher(d),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _usarMinhaPosicao,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Usar minha posição atual'),
                ),
              ),
              if (local != null)
                Text(
                  '${_descricaoLocal ?? 'Local escolhido'} '
                  '(${formatarCoordenada(local)})',
                  style: TextStyle(color: cores.onSurfaceVariant),
                ),
              if (_erroLocal case final erro?)
                Text(erro, style: TextStyle(color: cores.error)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Capacidade', style: rotulo),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('campo-capacidade-abrigo'),
                          controller: _capacidade,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(hintText: '120'),
                          validator: (v) {
                            final erro = _validarNumero(
                              v,
                              campo: 'a capacidade',
                            );
                            if (erro != null) return erro;
                            if (int.parse(v!) < 1) return 'Mínimo 1.';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vagas livres', style: rotulo),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('campo-vagas-abrigo'),
                          controller: _vagas,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(hintText: '40'),
                          validator: (v) {
                            final erro = _validarNumero(v, campo: 'as vagas');
                            if (erro != null) return erro;
                            final capacidade = int.tryParse(_capacidade.text);
                            if (capacidade != null &&
                                int.parse(v!) > capacidade) {
                              return 'Mais que a capacidade.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Abrigo ativo'),
                subtitle: const Text('Desativado, some da lista dos moradores'),
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
              ),
              const SizedBox(height: 12),
              if (_erro case final erro?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(erro, style: TextStyle(color: cores.error)),
                ),
              PrimaryButton(
                text: _editando ? 'Salvar alterações' : 'Cadastrar abrigo',
                onPressed: _salvar,
                loading: _salvando,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
