import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
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
      home: const TelaInicialProvisoria(),
    );
  }
}

/// Tela provisória até a navegação com barra inferior (próximo passo).
class TelaInicialProvisoria extends StatelessWidget {
  const TelaInicialProvisoria({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('EnchenteAlerta')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop, size: 72, color: cores.primary),
              const SizedBox(height: 16),
              Text(
                'Informação que te protege',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Firebase conectado',
                style: TextStyle(color: cores.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cores.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Alerta',
                  style: TextStyle(
                    color: cores.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
