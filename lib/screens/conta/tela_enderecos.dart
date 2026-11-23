import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../models/models.dart';
import '../../services/enderecos_service.dart';
import '../../services/erro_servico.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/busca_local.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../../widgets/widgets_conta.dart';
import '../defesa_civil/acoes_comuns.dart';

/// "Endereço padrão" do Perfil: os endereços da pessoa, com um marcado
/// como padrão (a casa), usado para filtrar os alertas da região (RF08).
class TelaEnderecos extends StatefulWidget {
  const TelaEnderecos({super.key});

  @override
  State<TelaEnderecos> createState() => _TelaEnderecosState();
}

class _TelaEnderecosState extends State<TelaEnderecos> {
  final _servico = EnderecosService.instance;

  @override
  void initState() {
    super.initState();
    _servico.iniciar();
  }

  Future<void> _abrir([Endereco? e]) async {
    final salvo = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => TelaFormularioEndereco(endereco: e)));
    if (salvo == true && mounted) {
      mostrarMensagem(
          context, e == null ? 'Endereço cadastrado.' : 'Endereço atualizado.');
    }
  }

  Future<void> _excluir(Endereco e) async {
    final ok = await confirmarAcao(context,
        titulo: 'Excluir endereço?',
        texto: '${e.logradouro} será removido da sua conta.',
        botao: 'Excluir');
    if (!ok || !mounted) return;
    await executarComAviso(context, () => _servico.excluir(e),
        sucesso: 'Endereço excluído.');
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: barraConta(context, 'Meus endereços',
          ajuda: TextosAjuda.enderecos),
      body: ValueListenableBuilder<List<Endereco>>(
        valueListenable: _servico.enderecos,
        builder: (context, lista, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'O endereço padrão é usado para mostrar só os alertas da sua '
              'região. Sem endereço, o app usa a sua posição atual.',
              style: TextStyle(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _abrir(),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Novo endereço'),
            ),
            const SizedBox(height: 16),
            if (lista.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Nenhum endereço cadastrado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: cores.onSurfaceVariant),
                ),
              ),
            for (final e in lista)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    e.padrao ? Icons.home : Icons.place_outlined,
                    color: e.padrao ? AppColors.alerta : cores.primary,
                  ),
                  title: Text(e.logradouro),
                  subtitle: Text(e.padrao
                      ? '${e.bairro} · ${e.cidade}\nEndereço padrão'
                      : '${e.bairro} · ${e.cidade}'),
                  isThreeLine: e.padrao,
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Opções do endereço',
                    onSelected: (op) => switch (op) {
                      'padrao' => executarComAviso(
                          context, () => _servico.definirPadrao(e),
                          sucesso: 'Endereço padrão alterado.'),
                      'editar' => _abrir(e),
                      _ => _excluir(e),
                    },
                    itemBuilder: (_) => [
                      if (!e.padrao)
                        const PopupMenuItem(
                            value: 'padrao', child: Text('Usar como padrão')),
                      const PopupMenuItem(value: 'editar', child: Text('Editar')),
                      const PopupMenuItem(
                          value: 'excluir', child: Text('Excluir')),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cadastro e edição de um endereço.
class TelaFormularioEndereco extends StatefulWidget {
  const TelaFormularioEndereco({super.key, this.endereco});

  final Endereco? endereco;

  @override
  State<TelaFormularioEndereco> createState() => _TelaFormularioEnderecoState();
}

class _TelaFormularioEnderecoState extends State<TelaFormularioEndereco> {
  final _form = GlobalKey<FormState>();
  late final _logradouro =
      TextEditingController(text: widget.endereco?.logradouro);
  late final _bairro = TextEditingController(text: widget.endereco?.bairro);
  late final _cidade =
      TextEditingController(text: widget.endereco?.cidade ?? 'Aracaju');
  late LatLng? _local = widget.endereco?.localizacao;
  late String? _descricaoLocal =
      widget.endereco == null ? null : 'Local salvo do endereço';
  late bool _padrao = widget.endereco?.padrao ?? true;
  String? _erroLocal;
  bool _salvando = false;

  @override
  void dispose() {
    for (final c in [_logradouro, _bairro, _cidade]) {
      c.dispose();
    }
    super.dispose();
  }

  void _aoEscolherLocal(LatLng ponto, String nome, String? completo) {
    setState(() {
      _local = ponto;
      _descricaoLocal = completo ?? nome;
      _erroLocal = null;
      // Sugestão da busca já preenche a rua, se estiver vazia.
      if (completo != null && _logradouro.text.trim().isEmpty) {
        _logradouro.text = nome;
      }
    });
  }

  String? _obrigatorio(String? v, String campo, int max) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Informe $campo.';
    if (t.length > max) return 'Use no máximo $max caracteres.';
    return null;
  }

  Future<void> _salvar() async {
    final valido = _form.currentState?.validate() ?? false;
    setState(() => _erroLocal =
        _local == null ? 'Escolha o local no mapa (busca ou posição).' : null);
    if (!valido || _local == null) return;
    setState(() => _salvando = true);
    try {
      await EnderecosService.instance.salvar(Endereco(
        id: widget.endereco?.id ?? '',
        logradouro: _logradouro.text.trim(),
        bairro: _bairro.text.trim(),
        cidade: _cidade.text.trim(),
        localizacao: _local!,
        padrao: _padrao,
      ));
      if (mounted) Navigator.pop(context, true);
    } on ServicoException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.endereco != null;
    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: barraConta(context, editando ? 'Editar endereço' : 'Novo endereço',
          ajuda: TextosAjuda.enderecos),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Local no mapa',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            BuscaLocal(
              local: _local,
              descricao: _descricaoLocal,
              dica: 'Buscar a rua da sua casa',
              erro: _erroLocal,
              aoEscolher: _aoEscolherLocal,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('campo-logradouro'),
              controller: _logradouro,
              maxLength: 120,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Rua e número', hintText: 'Ex.: Rua A, 120'),
              validator: (v) => _obrigatorio(v, 'a rua', 120),
            ),
            TextFormField(
              key: const Key('campo-bairro'),
              controller: _bairro,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Bairro'),
              validator: (v) => _obrigatorio(v, 'o bairro', 80),
            ),
            TextFormField(
              key: const Key('campo-cidade'),
              controller: _cidade,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Cidade'),
              validator: (v) => _obrigatorio(v, 'a cidade', 80),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Usar como endereço padrão'),
              subtitle: const Text('Os alertas da região contam a partir dele'),
              value: _padrao,
              onChanged: (v) => setState(() => _padrao = v),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: editando ? 'Salvar alterações' : 'Cadastrar endereço',
              onPressed: _salvar,
              loading: _salvando,
            ),
          ],
        ),
      ),
    );
  }
}
