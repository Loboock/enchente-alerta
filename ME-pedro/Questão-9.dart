
import 'dart:math';

void main() {
  for (int numero = 1000; numero <= 9999; numero++) {
    int parte1 = numero ~/ 100;
    int parte2 = numero % 100;

    int soma = parte1 + parte2;
    int resultado = soma * soma;

    if (resultado == numero) {
      print(numero);
    }
  }
}
