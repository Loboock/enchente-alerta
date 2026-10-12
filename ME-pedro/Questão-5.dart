
import 'dart:io';

void main() {
  stdout.write('Quantidade de recem-nascidos: ');
  int n = int.parse(stdin.readLineSync()!);

  int baixo = 0;
  int normal = 0;
  int alto = 0;

  String nomeMeninaMaisPesada = '';
  double maiorPesoFeminino = -1;

  for (int i = 1; i <= n; i++) {
    stdout.write('\nNome: ');
    String nome = stdin.readLineSync()!;

    stdout.write('Sexo (M/F): ');
    String sexo = stdin.readLineSync()!.toUpperCase();

    stdout.write('Peso em kg: ');
    double peso = double.parse(stdin.readLineSync()!);

    String classificacao;

    if (peso >= 0 && peso <= 2) {
      classificacao = 'Baixo Peso';
      baixo++;
    } else if (peso > 2 && peso <= 4) {
      classificacao = 'Normal';
      normal++;
    } else if (peso > 4) {
      classificacao = 'Alto Peso';
      alto++;
    } else {
      classificacao = 'Peso invalido';
    }

    print('$nome | $sexo | $classificacao');

    if (sexo == 'F' && peso >= 0 && peso > maiorPesoFeminino) {
      maiorPesoFeminino = peso;
      nomeMeninaMaisPesada = nome;
    }
  }

  if (nomeMeninaMaisPesada.isNotEmpty) {
    print('\nRecem-nascida com maior peso: $nomeMeninaMaisPesada');
  } else {
    print('\nNenhuma menina cadastrada.');
  }

  if (n > 0) {
    print('Percentual baixo peso: ${baixo / n * 100}%');
    print('Percentual normal: ${normal / n * 100}%');
    print('Percentual alto peso: ${alto / n * 100}%');
  }
}
