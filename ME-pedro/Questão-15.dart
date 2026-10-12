
import 'dart:io';

void main() {
  print('Quantidade de bois:');
  int n = int.parse(stdin.readLineSync()!);

  List<int> numeros = [];
  List<double> pesos = [];

  for (int i = 0; i < n; i++) {
    print('Numero do boi ${i + 1}:');
    numeros.add(int.parse(stdin.readLineSync()!));

    print('Peso do boi ${i + 1}:');
    pesos.add(double.parse(stdin.readLineSync()!));
  }

  String continuar = 'S';

  while (continuar == 'S') {
    print('Peso minimo:');
    double pesoMinimo = double.parse(stdin.readLineSync()!);

    print('Peso maximo:');
    double pesoMaximo = double.parse(stdin.readLineSync()!);

    if (pesoMinimo > pesoMaximo) {
      print('O peso minimo nao pode ser maior que o peso maximo.');
    } else {
      bool encontrou = false;

      for (int i = 0; i < n; i++) {
        if (pesos[i] >= pesoMinimo && pesos[i] <= pesoMaximo) {
          print('Boi ${numeros[i]} - Peso ${pesos[i]}');
          encontrou = true;
        }
      }

      if (!encontrou) {
        print('Nenhum boi encontrado nessa faixa de peso.');
      }
    }

    print('Outra pesquisa? (S/N):');
    continuar = stdin.readLineSync()!.toUpperCase();
  }
}
