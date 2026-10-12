
import 'dart:io';

List<int> lerVetor(int n) {
  List<int> v = [];

  for (int i = 0; i < n; i++) {
    print('Elemento ${i + 1}:');
    v.add(int.parse(stdin.readLineSync()!));
  }

  return v;
}

List<int> somarVetores(List<int> a, List<int> b) {
  List<int> c = [];

  for (int i = 0; i < a.length; i++) {
    c.add(a[i] + b[i]);
  }

  return c;
}

int somaTotal(List<int> v) {
  int soma = 0;

  for (int i = 0; i < v.length; i++) {
    soma += v[i];
  }

  return soma;
}

void main() {
  print('Tamanho dos vetores:');
  int n = int.parse(stdin.readLineSync()!);

  print('Vetor A:');
  List<int> a = lerVetor(n);

  print('Vetor B:');
  List<int> b = lerVetor(n);

  List<int> c = somarVetores(a, b);

  print('Vetor C: $c');
  print('Soma dos elementos de C: ${somaTotal(c)}');
}
