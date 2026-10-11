
import 'dart:io';

void main() {
  stdout.write('Digite o numero de termos: ');
  int n = int.parse(stdin.readLineSync()!);

  int a = 15;
  int b = 100;
  int c = 2;

  for (int i = 1; i <= n; i++) {
    if (i % 3 == 1) {
      print(a);
      a += 5;
    } else if (i % 3 == 2) {
      print(b);
      b -= 10;
    } else {
      print(c);
      c *= 2;
    }
  }
}
