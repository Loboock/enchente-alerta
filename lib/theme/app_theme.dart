import 'package:flutter/material.dart';

/// Cores do protótipo de alta fidelidade (docs/prototipoAltaFidelidade.pdf.pdf).
///
/// Azul-escuro como cor principal e laranja-amarelado como destaque de alerta
/// (RNF10 — alto contraste).
class AppColors {
  AppColors._();

  static const azul = Color(0xFF1A4D8F);
  static const azulMarinho = Color(0xFF172447);
  static const azulClaro = Color(0xFF95B2D0);
  static const azulFundo = Color(0xFFD9E3F5);
  static const alerta = Color(0xFFFF8D28);
  static const perigo = Color(0xFFD32F2F);
  static const seguro = Color(0xFF16A34A);
  static const cinzaTexto = Color(0xFF737D8C);
  static const cinzaBorda = Color(0xFFD1D9E3);
  static const fundoClaro = Color(0xFFF2F4F7);

  // Modo noturno (RNF03): fundo azul-marinho bem escuro, não preto puro.
  static const fundoEscuro = Color(0xFF0E1630);
  static const superficieEscura = azulMarinho;
}

/// Temas claro e escuro do app (RNF02 acessibilidade, RNF03 modo noturno,
/// RNF10 alto contraste).
class AppTheme {
  AppTheme._();

  static ThemeData get claro => _construir(
        const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.azul,
          onPrimary: Colors.white,
          primaryContainer: AppColors.azulFundo,
          onPrimaryContainer: AppColors.azulMarinho,
          secondary: AppColors.alerta,
          onSecondary: AppColors.azulMarinho,
          error: AppColors.perigo,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.azulMarinho,
          onSurfaceVariant: AppColors.cinzaTexto,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: AppColors.fundoClaro,
          surfaceContainer: AppColors.fundoClaro,
          outline: AppColors.cinzaBorda,
        ),
        fundo: AppColors.fundoClaro,
        barraTopo: AppColors.azul,
      );

  static ThemeData get escuro => _construir(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.azulClaro,
          onPrimary: AppColors.azulMarinho,
          primaryContainer: AppColors.azul,
          onPrimaryContainer: Colors.white,
          secondary: AppColors.alerta,
          onSecondary: AppColors.azulMarinho,
          error: Color(0xFFFF6B6B),
          onError: AppColors.azulMarinho,
          surface: AppColors.superficieEscura,
          onSurface: Colors.white,
          onSurfaceVariant: AppColors.azulClaro,
          surfaceContainerLowest: AppColors.fundoEscuro,
          surfaceContainerLow: AppColors.superficieEscura,
          surfaceContainer: AppColors.superficieEscura,
          outline: Color(0xFF3A4A6B),
        ),
        fundo: AppColors.fundoEscuro,
        barraTopo: AppColors.azulMarinho,
      );

  static ThemeData _construir(
    ColorScheme cores, {
    required Color fundo,
    required Color barraTopo,
  }) {
    final base = ThemeData(colorScheme: cores, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: fundo,
      // RNF02: textos um pouco maiores que o padrão para leitura em emergência.
      textTheme: base.textTheme
          .copyWith(
            bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 17),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 15),
          )
          .apply(bodyColor: cores.onSurface, displayColor: cores.onSurface),
      // RNF02: alvos de toque com no mínimo 48 dp.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: barraTopo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azul,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cores.primary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: cores.primary, width: 1.5),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cores.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cores.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cores.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cores.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: cores.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cores.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cores.surface,
        indicatorColor: cores.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
