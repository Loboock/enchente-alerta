import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/tela_principal.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EnchenteAlertaApp());
}

class EnchenteAlertaApp extends StatelessWidget {
  const EnchenteAlertaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EnchenteAlerta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      darkTheme: AppTheme.escuro,
      // RNF03: segue o modo noturno do aparelho. A opção manual entra na
      // tela de Perfil, mais adiante.
      themeMode: ThemeMode.system,
      home: const TelaPrincipal(),
    );
  }
}
