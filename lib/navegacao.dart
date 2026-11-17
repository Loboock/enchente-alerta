import 'package:flutter/material.dart';

/// Aba selecionada na tela principal (0 = Início ... 4 = Guia).
///
/// É global porque as telas que abrem por cima da principal (abrigos, rota)
/// também têm a barra inferior e precisam mandar o usuário para uma aba.
final ValueNotifier<int> abaAtual = ValueNotifier<int>(0);

/// Fecha as telas abertas por cima e mostra a aba escolhida.
void irParaAba(BuildContext context, int indice) {
  abaAtual.value = indice;
  Navigator.of(context).popUntil((rota) => rota.isFirst);
}
