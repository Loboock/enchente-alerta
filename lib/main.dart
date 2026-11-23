import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/tela_principal.dart';
import 'services/conexao_service.dart';
import 'services/mapa_offline_service.dart';
import 'theme/app_theme.dart';
import 'theme/modo_tema.dart';
import 'widgets/faixa_sem_internet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Faixa "Sem internet" e região do mapa guardada para uso offline.
  ConexaoService.instance.iniciar();
  MapaOfflineService.instance.carregarRegiao();
  // Modo claro/escuro escolhido pela pessoa (ou o do aparelho).
  await ModoTema.instance.carregar();
  runApp(const EnchenteAlertaApp());
}

class EnchenteAlertaApp extends StatelessWidget {
  const EnchenteAlertaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // RNF03: segue o modo noturno do aparelho até a pessoa escolher outro
    // no botão de tema da tela Início (lib/theme/modo_tema.dart).
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ModoTema.instance.modo,
      builder: (context, modo, _) => MaterialApp(
        title: 'EnchenteAlerta',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro,
        darkTheme: AppTheme.escuro,
        themeMode: modo,
        // Sem internet, a faixa de aviso aparece no rodapé de todas as telas.
        builder: (context, child) =>
            ComFaixaSemInternet(child: child ?? const SizedBox.shrink()),
        home: const TelaPrincipal(),
      ),
    );
  }
}
