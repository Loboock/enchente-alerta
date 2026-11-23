import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../widgets/ajuda.dart';
import '../../widgets/scaffold_com_abas.dart';
import '../../widgets/widgets_conta.dart';

/// Tela "Meus dados" do Perfil: os dados da conta num lugar só, como nos
/// outros apps. Só o nome pode ser alterado aqui; e-mail, tipo de conta e
/// data de criação aparecem só para consulta.
///
/// Recebe os dados e as ações prontos (do AuthService, na tela Perfil),
/// para poder ser testada sem o Firebase.
class TelaMeusDados extends StatefulWidget {
  const TelaMeusDados({
    super.key,
    required this.nome,
    required this.email,
    required this.perfil,
    required this.aoSalvarNome,
    required this.aoAlterarSenha,
    this.criadaEm,
  });

  final String nome;
  final String email;
  final PerfilUsuario perfil;
  final DateTime? criadaEm;

  /// Grava o nome novo. Lança uma exceção com a mensagem do erro.
  final Future<void> Function(String nome) aoSalvarNome;

  /// Envia o e-mail para criar uma senha nova.
  final Future<void> Function() aoAlterarSenha;

  @override
  State<TelaMeusDados> createState() => _TelaMeusDadosState();
}

class _TelaMeusDadosState extends State<TelaMeusDados> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.nome);
  late String _nomeSalvo = widget.nome;
  bool _salvando = false;
  bool _enviandoSenha = false;

  @override
  void initState() {
    super.initState();
    _nome.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  bool get _mudou => _nome.text.trim() != _nomeSalvo;

  Future<void> _salvar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _salvando = true);
    final novo = _nome.text.trim();
    try {
      await widget.aoSalvarNome(novo);
      _nomeSalvo = novo;
      if (mounted) showMsg(context, 'Dados atualizados.');
    } catch (e) {
      if (mounted) showMsg(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _alterarSenha() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Text('Vamos enviar para ${widget.email} um link para você '
            'criar uma senha nova.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Enviar link'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _enviandoSenha = true);
    try {
      await widget.aoAlterarSenha();
      if (mounted) {
        showMsg(context, 'Link enviado. Confira o seu e-mail.');
      }
    } catch (e) {
      if (mounted) showMsg(context, e.toString());
    } finally {
      if (mounted) setState(() => _enviandoSenha = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final criadaEm = widget.criadaEm;

    return ScaffoldComAbas(
      abaAtiva: 3,
      appBar: barraConta(context, 'Meus dados', ajuda: TextosAjuda.meusDados),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Secao('Informações pessoais'),
              TextFormField(
                key: const Key('campo-nome'),
                controller: _nome,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _mudou ? _salvar() : null,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Informe o seu nome.';
                  if (t.length < 2) return 'Use pelo menos 2 letras.';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _Informacao(
                icone: Icons.mail_outline,
                rotulo: 'E-mail',
                valor: widget.email,
                ajuda: 'Usado para entrar na conta. Não pode ser alterado.',
              ),
              const SizedBox(height: 24),
              const _Secao('Conta'),
              _Informacao(
                icone: widget.perfil == PerfilUsuario.defesaCivil
                    ? Icons.shield_outlined
                    : Icons.home_outlined,
                rotulo: 'Tipo de conta',
                valor: widget.perfil.rotulo,
              ),
              if (criadaEm != null)
                _Informacao(
                  icone: Icons.event_outlined,
                  rotulo: 'Membro desde',
                  valor: _data(criadaEm),
                ),
              const SizedBox(height: 24),
              const _Secao('Segurança'),
              OutlinedButton.icon(
                onPressed: _enviandoSenha ? null : _alterarSenha,
                icon: const Icon(Icons.lock_reset),
                label: const Text('Alterar senha'),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Salvar alterações',
                onPressed: _mudou ? _salvar : null,
                loading: _salvando,
              ),
              const SizedBox(height: 8),
              Text(
                'Seu nome nunca aparece nos avisos que você envia.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cores.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "22 de novembro de 2026".
String _data(DateTime d) {
  const meses = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho',
    'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];
  return '${d.day} de ${meses[d.month - 1]} de ${d.year}';
}

class _Secao extends StatelessWidget {
  const _Secao(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      );
}

/// Linha só de leitura: ícone, rótulo pequeno e valor.
class _Informacao extends StatelessWidget {
  const _Informacao({
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.ajuda,
  });

  final IconData icone;
  final String rotulo;
  final String valor;
  final String? ajuda;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 16, top: 2),
            child: Icon(icone, color: cores.onSurfaceVariant),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo,
                    style: TextStyle(
                        color: cores.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 2),
                Text(valor,
                    style: TextStyle(color: cores.onSurface, fontSize: 16)),
                if (ajuda != null) ...[
                  const SizedBox(height: 2),
                  Text(ajuda!,
                      style: TextStyle(
                          color: cores.onSurfaceVariant, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
