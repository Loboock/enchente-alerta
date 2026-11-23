import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/cores_gravidade.dart';

/// Botão arredondado colorido da gravidade (Leve, Moderado, Grave), usado
/// em Criar aviso e no formulário de alerta da Defesa Civil.
class BotaoGravidade extends StatelessWidget {
  const BotaoGravidade({
    super.key,
    required this.gravidade,
    required this.selecionada,
    required this.aoTocar,
  });

  final Gravidade gravidade;
  final bool selecionada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cor = gravidade.cor(Theme.of(context).colorScheme);
    return Semantics(
      button: true,
      selected: selecionada,
      label: 'Gravidade ${gravidade.rotulo}',
      excludeSemantics: true,
      child: Material(
        color: selecionada ? cor : cor.withValues(alpha: 0.15),
        shape: StadiumBorder(
          side: BorderSide(color: cor, width: selecionada ? 3 : 1.5),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selecionada) ...[
                  const Icon(Icons.check, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    gravidade.rotulo,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selecionada ? Colors.white : cor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
