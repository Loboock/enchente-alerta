
import 'dart:io';

void main() {
  print('Digite um numero:');
  String numero = stdin.readLineSync()!;

  String invertido = '';

  for (int i = numero.length - 1; i >= 0; i--) {
    invertido += numero[i];
  }

  print('Impressao: $invertido');
}
