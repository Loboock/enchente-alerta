
import 'dart:io';
import 'dart:math';

void main() {
  Random random = Random();
  int sorteado = random.nextInt(100) + 1;

  int minimo = 1;
  int maximo = 100;
  int palpite = 0;

  while (palpite != sorteado) {
    stdout.write('Digite um numero entre $minimo e $maximo: ');
    palpite = int.parse(stdin.readLineSync()!);

    if (palpite < minimo || palpite > maximo) {
      print('Digite um numero dentro do intervalo informado.');
      continue;
    }

    if (palpite < sorteado) {
      minimo = palpite + 1;
      print('O numero esta entre $minimo e $maximo.');
    } else if (palpite > sorteado) {
      maximo = palpite - 1;
      print('O numero esta entre $minimo e $maximo.');
    } else {
      print('Parabens! Voce acertou!');
    }
  }
}
