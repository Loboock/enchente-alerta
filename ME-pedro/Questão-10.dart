
import 'dart:io';

void main() {
  int fem = 0, masc = 0;
  int mascComExp = 0, somaIdades = 0;
  int masc45 = 0;
  int mulher30Exp = 0;
  int menorIdade = 999;
  String nomeMenor = '';

  print('Nome (FIM para parar):');
  String nome = stdin.readLineSync()!;

  while (nome.toUpperCase() != 'FIM') {
    print('Sexo (M/F):');
    String sexo = stdin.readLineSync()!.toUpperCase();

    print('Idade:');
    int idade = int.parse(stdin.readLineSync()!);

    print('Tem experiência (S/N):');
    String exp = stdin.readLineSync()!.toUpperCase();

    if (sexo == 'M') {
      masc++;

      if (exp == 'S') {
        mascComExp++;
        somaIdades += idade;
      }

      if (idade > 45) {
        masc45++;
      }
    } else if (sexo == 'F') {
      fem++;

      if (exp == 'S') {
        if (idade < 30) {
          mulher30Exp++;
        }

        if (idade < menorIdade) {
          menorIdade = idade;
          nomeMenor = nome;
        }
      }
    } else {
      print('Sexo invalido. Use M ou F.');
    }

    print('Nome (FIM para parar):');
    nome = stdin.readLineSync()!;
  }

  print('a) Mulheres: $fem | Homens: $masc');

  if (mascComExp > 0) {
    print('b) Idade media dos homens com experiencia: '
        '${(somaIdades / mascComExp).toStringAsFixed(2)}');
  } else {
    print('b) Nao ha homens com experiencia.');
  }

  if (masc > 0) {
    print('c) Homens com mais de 45 anos: '
        '${(masc45 * 100 / masc).toStringAsFixed(2)}%');
  } else {
    print('c) Nao ha homens cadastrados.');
  }

  print('d) Mulheres com menos de 30 anos e com experiencia: $mulher30Exp');

  if (nomeMenor.isNotEmpty) {
    print('e) Candidata mais nova com experiencia: $nomeMenor');
  } else {
    print('e) Nao ha candidatas com experiencia.');
  }
}
