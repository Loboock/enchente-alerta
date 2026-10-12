
import 'dart:io';

void main() {
  List<List<int>> vetores = [];

  for (int k = 1; k <= 4; k++) {
    print('Tamanho do vetor $k:');
    int n = int.parse(stdin.readLineSync()!);

    List<int> v = [];

    for (int i = 0; i < n; i++) {
      print('Elemento ${i + 1}:');
      v.add(int.parse(stdin.readLineSync()!));
    }

    vetores.add(v);
  }

  // a) Junta os elementos dos quatro vetores e ordena.
  List<int> quinto = [];

  for (int k = 0; k < 4; k++) {
    for (int i = 0; i < vetores[k].length; i++) {
      quinto.add(vetores[k][i]);
    }
  }

  quinto.sort();
  print('a) Quinto vetor: $quinto');

  // b) Valores distintos presentes nos quatro vetores.
  List<int> inter = [];

  for (int i = 0; i < vetores[0].length; i++) {
    int x = vetores[0][i];

    if (vetores[1].contains(x) &&
        vetores[2].contains(x) &&
        vetores[3].contains(x) &&
        !inter.contains(x)) {
      inter.add(x);
    }
  }

  print('b) Intersecao: $inter');
}
