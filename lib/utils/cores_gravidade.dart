import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

extension CorDaGravidade on Gravidade {
  /// Cor do texto de risco; segue o tema claro/escuro.
  Color cor(ColorScheme cores) => switch (this) {
        Gravidade.leve => AppColors.seguro,
        Gravidade.moderado => cores.secondary,
        Gravidade.grave => cores.error,
      };
}
