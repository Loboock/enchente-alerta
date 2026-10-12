
import 'dart:io';

void main() {
  print('Valor de N:');
  int n = int.parse(stdin.readLineSync()!);

  List<int> v = [];

  for (int i = 0; i < n; i++) {
    print('Elemento ${i + 1}:');
    v.add(int.parse(stdin.readLineSync()!));
  }

  List<int> valores = [];
  List<int> contagem = [];

  for (int i = 0; i < n; i++) {
    int pos = valores.indexOf(v[i]);

    if (pos == -1) {
      valores.add(v[i]);
      contagem.add(1);
    } else {
      contagem[pos]++;
    }
  }

  for (int i = 0; i < valores.length; i++) {
    print('${valores[i]} - ${contagem[i]}');
  }
}
