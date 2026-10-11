
import 'dart:io';
import 'dart:math';

void main() {
  stdout.write('Digite o numero de termos: ');
  int n = int.parse(stdin.readLineSync()!);

  double soma = 0;

  for (int i = 1; i <= n; i++) {
    double base = 2 * i + 1;
    int expoente = 4 * i;
    double denominador = 5 * i;

    soma += pow(base, expoente) / denominador;
  }

  print('Soma = $soma');
}
