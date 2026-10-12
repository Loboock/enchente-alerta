
import 'dart:io';

void main() {
  int total = 0;
  int homens = 0;
  int mulheres = 0;

  int menorPontuacaoM = 5001;
  String nomeMenorM = '';

  int maiorPontuacaoSIM = -1;
  String codigoMaiorSIM = '';

  while (true) {
    stdout.write('Codigo (00000 para terminar): ');
    String codigo = stdin.readLineSync()!;

    if (codigo == '00000') {
      break;
    }

    stdout.write('Curso (CC ou SI): ');
    String curso = stdin.readLineSync()!.toUpperCase();

    stdout.write('Nome: ');
    String nome = stdin.readLineSync()!;

    stdout.write('Sexo (M/F): ');
    String sexo = stdin.readLineSync()!.toUpperCase();

    stdout.write('Pontuacao (0 a 5000): ');
    int pontuacao = int.parse(stdin.readLineSync()!);

    total++;

    if (sexo == 'M') {
      homens++;

      if (pontuacao < menorPontuacaoM) {
        menorPontuacaoM = pontuacao;
        nomeMenorM = nome;
      }

      if (curso == 'SI' && pontuacao > maiorPontuacaoSIM) {
        maiorPontuacaoSIM = pontuacao;
        codigoMaiorSIM = codigo;
      }
    } else if (sexo == 'F') {
      mulheres++;
    }

    if (curso == 'CC' && pontuacao > 2500) {
      print('CC acima de 2500: $codigo | $nome | $pontuacao');
    }
  }

  print('\n--- Resultados ---');

  if (nomeMenorM.isNotEmpty) {
    print('Homem com menor pontuacao: $nomeMenorM');
  } else {
    print('Nenhum candidato masculino cadastrado.');
  }

  if (codigoMaiorSIM.isNotEmpty) {
    print('Codigo do homem com maior pontuacao em SI: '
        '$codigoMaiorSIM');
  } else {
    print('Nenhum candidato masculino de SI cadastrado.');
  }

  if (total > 0) {
    print('Percentual masculino: ${homens / total * 100}%');
    print('Percentual feminino: ${mulheres / total * 100}%');
  } else {
    print('Nenhum candidato cadastrado.');
  }
}
