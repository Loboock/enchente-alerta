
import 'dart:io';

void main() {
  double somaLiqM = 0, somaLiqF = 0;
  int qtdM = 0, qtdF = 0;

  print('Codigo (9999 para parar):');
  int codigo = int.parse(stdin.readLineSync()!);

  while (codigo != 9999) {
    print('Nome:');
    String nome = stdin.readLineSync()!;

    print('Sexo (M/F):');
    String sexo = stdin.readLineSync()!.toUpperCase();

    print('Horas de aula:');
    int horas = int.parse(stdin.readLineSync()!);

    double bruto = horas * 12.30;
    double liquido;

    if (sexo == 'M') {
      liquido = bruto - bruto * 0.10;
      somaLiqM += liquido;
      qtdM++;
    } else if (sexo == 'F') {
      liquido = bruto - bruto * 0.05;
      somaLiqF += liquido;
      qtdF++;
    } else {
      print('Sexo invalido. Registro nao contabilizado.');
      print('Codigo (9999 para parar):');
      codigo = int.parse(stdin.readLineSync()!);
      continue;
    }

    print('Codigo: $codigo | Nome: $nome | '
        'Bruto: R\$ ${bruto.toStringAsFixed(2)} | '
        'Liquido: R\$ ${liquido.toStringAsFixed(2)}');

    print('Codigo (9999 para parar):');
    codigo = int.parse(stdin.readLineSync()!);
  }

  if (qtdM > 0) {
    print('Media liquida dos homens: R\$ '
        '${(somaLiqM / qtdM).toStringAsFixed(2)}');
  } else {
    print('Nenhum professor do sexo masculino cadastrado.');
  }

  if (qtdF > 0) {
    print('Media liquida das mulheres: R\$ '
        '${(somaLiqF / qtdF).toStringAsFixed(2)}');
  } else {
    print('Nenhuma professora do sexo feminino cadastrada.');
  }
}
