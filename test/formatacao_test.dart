import 'package:flutter_test/flutter_test.dart';

import 'package:enchente_alerta/utils/formatacao.dart';

void main() {
  test('Tempo desde o aviso no formato do protótipo', () {
    final agora = DateTime(2026, 11, 17, 15);
    String atras(Duration d) =>
        formatarTempoAtras(agora.subtract(d), agora: agora);

    expect(atras(const Duration(seconds: 20)), 'agora');
    expect(atras(const Duration(minutes: 10)), 'há 10 min');
    expect(atras(const Duration(hours: 2, minutes: 5)), 'há 2 h');
    expect(atras(const Duration(days: 1, hours: 3)), 'há 1 dia');
    expect(atras(const Duration(days: 3)), 'há 3 dias');
  });
}
