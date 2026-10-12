
import 'dart:io';

void main() {
  int quantidade = 0;
  int aprovados = 0;
  int totalFeminino = 0;
  int quantidadeFeminino = 0;

  double somaMedias = 0;
  double somaMediasFeminino = 0;

  double maiorMediaM = -1;
  double maiorMediaF = -1;

  String matriculaM = '';
  String matriculaF = '';

  while (true) {
    stdout.write('Matricula (00000 para terminar): ');
    String matricula = stdin.readLineSync()!;

    if (matricula == '00000') {
      break;
    }

    stdout.write('Nome: ');
    String nome = stdin.readLineSync()!;

    stdout.write('Sexo (M/F): ');
    String sexo = stdin.readLineSync()!.toUpperCase();

    stdout.write('Nota 1: ');
    double n1 = double.parse(stdin.readLineSync()!);

    stdout.write('Nota 2: ');
    double n2 = double.parse(stdin.readLineSync()!);

    stdout.write('Nota 3: ');
    double n3 = double.parse(stdin.readLineSync()!);

    stdout.write('Faltas: ');
    int faltas = int.parse(stdin.readLineSync()!);

    double media = (n1 + n2 + n3) / 3;
    bool aprovado = media >= 7 && faltas <= 18;

    quantidade++;
    somaMedias += media;

    if (aprovado) {
      aprovados++;

      if (sexo == 'M' && media > maiorMediaM) {
        maiorMediaM = media;
        matriculaM = matricula;
      }

      if (sexo == 'F' && media > maiorMediaF) {
        maiorMediaF = media;
        matriculaF = matricula;
      }
    }

    if (sexo == 'F') {
      quantidadeFeminino++;
      somaMediasFeminino += media;
    }

    print('Aluno: $nome | Media: ${media.toStringAsFixed(2)}');
    print(aprovado ? 'Aprovado' : 'Reprovado');
  }

  if (quantidade > 0) {
    print('\nMedia da turma: ${somaMedias / quantidade}');
    print('Percentual aprovados: '
        '${(aprovados / quantidade * 100).toStringAsFixed(2)}%');
  } else {
    print('\nNenhum aluno cadastrado.');
  }

  if (matriculaM.isNotEmpty) {
    print('Matricula do masculino com maior media aprovada: $matriculaM');
  } else {
    print('Nenhum aluno masculino aprovado.');
  }

  if (matriculaF.isNotEmpty) {
    print('Matricula do feminino com maior media aprovada: $matriculaF');
  } else {
    print('Nenhuma aluna feminina aprovada.');
  }

  if (quantidadeFeminino > 0) {
    print('Media das alunas: '
        '${somaMediasFeminino / quantidadeFeminino}');
  } else {
    print('Nenhuma aluna cadastrada.');
  }
}
