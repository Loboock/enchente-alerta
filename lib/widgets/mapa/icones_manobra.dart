import 'package:flutter/material.dart';

/// Ícone de cada código de manobra do OpenRouteService.
IconData iconeManobra(int tipo) => switch (tipo) {
      0 => Icons.turn_left, // esquerda
      1 => Icons.turn_right, // direita
      2 => Icons.turn_sharp_left, // esquerda fechada
      3 => Icons.turn_sharp_right, // direita fechada
      4 => Icons.turn_slight_left, // levemente à esquerda
      5 => Icons.turn_slight_right, // levemente à direita
      6 => Icons.straight, // siga em frente
      7 => Icons.roundabout_right, // entre na rotatória
      8 => Icons.roundabout_right, // saia da rotatória
      9 => Icons.u_turn_left, // retorno
      10 => Icons.flag, // chegada
      11 => Icons.navigation, // partida
      12 => Icons.fork_left, // mantenha à esquerda
      13 => Icons.fork_right, // mantenha à direita
      _ => Icons.straight,
    };
