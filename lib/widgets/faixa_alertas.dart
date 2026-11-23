import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/alertas_regiao.dart';
import '../services/alertas_service.dart';
import '../services/auth_service.dart';
import '../services/enderecos_service.dart';
import '../services/localizacao_service.dart';
import '../services/notificacoes_service.dart';
import '../services/perigos_service.dart';
import '../utils/cores_gravidade.dart';
import '../utils/formatacao.dart';

/// Faixa com o alerta ativo mais grave da Defesa Civil (RF01). Tocar
/// mostra todos os alertas ativos. Sem alerta ativo, não ocupa espaço.
///
/// Só mostra os alertas da região de quem usa o app (endereço padrão ou
/// posição, dentro do raio escolhido; ver alertas_regiao.dart). Com
/// [respeitarPreferencia] (tela Início), some para quem desligou os
/// alertas no Perfil (RF08). Na aba Avisos aparece sempre.
class FaixaAlertas extends StatefulWidget {
  const FaixaAlertas({
    super.key,
    this.respeitarPreferencia = false,
    this.margem = EdgeInsets.zero,
  });

  final bool respeitarPreferencia;

  /// Espaço em volta, só quando a faixa aparece.
  final EdgeInsets margem;

  @override
  State<FaixaAlertas> createState() => _FaixaAlertasState();
}

class _FaixaAlertasState extends State<FaixaAlertas> {
  @override
  void initState() {
    super.initState();
    AlertasService.instance.iniciar();
    EnderecosService.instance.iniciar();
    // Grava em "Notificações" os alertas que chegam para a pessoa.
    NotificacoesService.instance.iniciar();
  }

  @override
  Widget build(BuildContext context) {
    final servico = AlertasService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        servico.alertas,
        AuthService.instance,
        EnderecosService.instance.enderecos,
        LocalizacaoService.instance.posicao,
        PerigosService.instance.perigos,
      ]),
      builder: (context, _) {
        if (widget.respeitarPreferencia &&
            AuthService.instance.user != null &&
            !AuthService.instance.notificacoesAtivas) {
          return const SizedBox.shrink();
        }
        final ativos = alertasParaMim();
        if (ativos.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: widget.margem,
          child: _Faixa(alertas: ativos),
        );
      },
    );
  }
}

class _Faixa extends StatelessWidget {
  const _Faixa({required this.alertas});

  final List<Alerta> alertas;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final principal = alertas.first;
    final cor = principal.nivel.cor(cores);
    final outros = alertas.length - 1;

    return Semantics(
      button: true,
      label: 'Alerta da Defesa Civil: ${principal.titulo}',
      child: Material(
        color: cor,
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _mostrarTodos(context, alertas),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEFESA CIVIL · ${principal.nivel.rotulo.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        principal.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (outros > 0)
                        Text(
                          outros == 1
                              ? '+ 1 outro alerta'
                              : '+ $outros outros alertas',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _mostrarTodos(BuildContext context, List<Alerta> alertas) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (contexto) {
      final cores = Theme.of(contexto).colorScheme;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(contexto).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(
                'Alertas da Defesa Civil',
                style: TextStyle(
                  color: cores.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              for (final a in alertas) ...[
                Text(
                  a.nivel.rotulo.toUpperCase(),
                  style: TextStyle(
                    color: a.nivel.cor(cores),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  a.titulo,
                  style: TextStyle(
                    color: cores.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (a.descricao.isNotEmpty) Text(a.descricao),
                Text(
                  'Emitido ${formatarTempoAtras(a.emitidoEm)}',
                  style: TextStyle(color: cores.onSurfaceVariant, fontSize: 13),
                ),
                const Divider(height: 24),
              ],
            ],
          ),
        ),
      );
    },
  );
}
