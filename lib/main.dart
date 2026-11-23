import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/tela_principal.dart';
import 'services/conexao_service.dart';
import 'services/mapa_offline_service.dart';
import 'theme/app_theme.dart';
import 'widgets/faixa_sem_internet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Faixa "Sem internet" e região do mapa guardada para uso offline.
  ConexaoService.instance.iniciar();
  MapaOfflineService.instance.carregarRegiao();
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
      // Sem internet, a faixa de aviso aparece no rodapé de todas as telas.
      builder: (context, child) =>
          ComFaixaSemInternet(child: child ?? const SizedBox.shrink()),
      home: const TelaPrincipal(),
    );
  }
}
