
import 'dart:io';
import 'dart:math';

void main() {
  stdout.write('Digite o valor de X: ');
  double x = double.parse(stdin.readLineSync()!);

  stdout.write('Digite a quantidade de termos: ');
  int n = int.parse(stdin.readLineSync()!);

  double soma = 0;
  int f = 1;
  int direcao = 1;

  for (int i = 1; i <= n; i++) {
    int expoente = i + 1;

    double potencia = pow(x, expoente).toDouble();

    int fat = 1;
    for (int j = 1; j <= f; j++) {
      fat *= j;
    }

    soma += potencia / fat;

    if (f == 4) {
      direcao = -1;
    } else if (f == 1) {
      direcao = 1;
    }

    f += direcao;
  }

  print('Resultado da serie = $soma');
}
