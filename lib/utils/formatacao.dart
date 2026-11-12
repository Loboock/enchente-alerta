/// Distância no formato do protótipo: "630 m", "1,2 km", "21 km".
///
/// Com [compacto] sai sem espaço ("950m"), como nos números da rota.
String formatarDistancia(num metros, {bool compacto = false}) {
  String texto;
  if (metros < 1000) {
    texto = '${(metros / 10).round() * 10} m';
  } else {
    var km = (metros / 1000).toStringAsFixed(1).replaceAll('.', ',');
    if (km.endsWith(',0')) km = km.substring(0, km.length - 2);
    texto = '$km km';
  }
  return compacto ? texto.replaceAll(' ', '') : texto;
}

/// Minúsculas e sem acento, para a busca por endereço ("ginasio" acha "Ginásio").
String normalizarTexto(String texto) {
  const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const semAcento = 'aaaaaeeeeiiiiooooouuuucn';
  final saida = StringBuffer();
  for (final letra in texto.toLowerCase().split('')) {
    final i = comAcento.indexOf(letra);
    saida.write(i >= 0 ? semAcento[i] : letra);
  }
  return saida.toString().trim();
}
