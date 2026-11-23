import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Modo claro/escuro do app (RNF03).
///
/// Começa seguindo o aparelho. Quando a pessoa usa o botão de tema (tela
/// Início), a escolha passa a valer e fica guardada num arquivo do
/// aparelho, para continuar igual ao reabrir o app.
class ModoTema {
  ModoTema._();

  static final instance = ModoTema._();

  final modo = ValueNotifier<ThemeMode>(ThemeMode.system);

  static const _nomeArquivo = 'modo_tema.txt';

  /// Lê a escolha guardada. Sem arquivo (ou sem acesso), segue o aparelho.
  Future<void> carregar() async {
    try {
      final arquivo = await _arquivo();
      if (!await arquivo.exists()) return;
      switch ((await arquivo.readAsString()).trim()) {
        case 'escuro':
          modo.value = ThemeMode.dark;
        case 'claro':
          modo.value = ThemeMode.light;
      }
    } catch (_) {
      // Sem o plugin (ex.: flutter test) ou erro de leitura: usa o padrão.
    }
  }

  /// Troca para o contrário do tema que está na tela agora.
  void alternar(Brightness atual) {
    modo.value = atual == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    _salvar();
  }

  Future<void> _salvar() async {
    try {
      final arquivo = await _arquivo();
      await arquivo.writeAsString(
        modo.value == ThemeMode.dark ? 'escuro' : 'claro',
      );
    } catch (_) {
      // Não guardar não impede a troca de tema agora.
    }
  }

  Future<File> _arquivo() async {
    final pasta = await getApplicationSupportDirectory();
    return File('${pasta.path}/$_nomeArquivo');
  }
}

/// Botão do cabeçalho que alterna entre o modo claro e o escuro. Mostra a
/// lua no modo claro e o sol no modo escuro (o modo para onde vai).
class BotaoModoTema extends StatelessWidget {
  const BotaoModoTema({super.key});

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: escuro ? 'Ativar modo claro' : 'Ativar modo escuro',
      iconSize: 36,
      padding: const EdgeInsets.all(4),
      color: Colors.white,
      icon: Icon(escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ModoTema.instance.alternar(
        escuro ? Brightness.dark : Brightness.light,
      ),
    );
  }
}
