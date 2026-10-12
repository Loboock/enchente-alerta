
import 'dart:io';

void main() {
  print('Tamanho do vetor A:');
  int n1 = int.parse(stdin.readLineSync()!);

  List<int> a = [];
  print('Digite os elementos de A em ordem crescente:');

  for (int i = 0; i < n1; i++) {
    a.add(int.parse(stdin.readLineSync()!));
  }

  print('Tamanho do vetor B:');
  int n2 = int.parse(stdin.readLineSync()!);

  List<int> b = [];
  print('Digite os elementos de B em ordem crescente:');

  for (int i = 0; i < n2; i++) {
    b.add(int.parse(stdin.readLineSync()!));
  }

  List<int> c = [];
  int i = 0, j = 0;

  while (i < n1 && j < n2) {
    if (a[i] <= b[j]) {
      c.add(a[i]);
      i++;
    } else {
      c.add(b[j]);
      j++;
    }
  }

  while (i < n1) {
    c.add(a[i]);
    i++;
  }

  while (j < n2) {
    c.add(b[j]);
    j++;
  }

  print('Vetor C: $c');
}
