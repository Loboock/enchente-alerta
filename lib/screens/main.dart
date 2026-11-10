import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'theme.dart';

void main() => runApp(const EnchenteApp());

class EnchenteApp extends StatelessWidget {
  const EnchenteApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Enchente Alerta',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: kBlue, primary: kBlue),
          scaffoldBackgroundColor: kBg,
        ),
        home: const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: AuthService.instance,
        builder: (_, __) => AuthService.instance.user != null
            ? const ProfileScreen()
            : const LoginScreen(),
      );
}
