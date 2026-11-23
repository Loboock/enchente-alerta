/// Configurações do app definidas na hora de rodar/compilar.
///
/// A chave do OpenRouteService NÃO fica no código: passe com
///   flutter run --dart-define=ORS_API_KEY=sua_chave
/// ou guarde num arquivo fora do git (ex.: `config.json`) e rode
///   flutter run --dart-define-from-file=config.json
/// Detalhes em docs/rotas-e-mapa.md.
class Config {
  Config._();

  /// Chave gratuita de https://openrouteservice.org (rotas e endereços).
  static const orsApiKey = String.fromEnvironment('ORS_API_KEY');

  static bool get temChaveOrs => orsApiKey.isNotEmpty;

  /// Chave grátis de https://carto.com/basemaps/apikey (opcional). Com ela,
  /// o fundo do mapa usa o visual limpo da CARTO; sem ela, usa o
  /// OpenStreetMap padrão (escurecido no modo noturno).
  static const cartoApiKey = String.fromEnvironment('CARTO_API_KEY');

  static bool get temChaveCarto => cartoApiKey.isNotEmpty;

  /// Com `--dart-define=LOCALIZACAO_TESTE=true` o app ignora o GPS e usa a
  /// posição fixa da Farolândia (útil no emulador, que fica nos EUA).
  static const usarLocalizacaoDeTeste =
      bool.fromEnvironment('LOCALIZACAO_TESTE');

  /// Quantas pessoas (contando quem reportou) precisam confirmar um aviso
  /// da comunidade para que as rotas passem a desviar dele. Com 1, a rota
  /// desvia assim que o aviso é enviado.
  static const confirmacoesParaBloquear = 1;

  /// true = basta o aviso de quem reportou para as rotas desviarem.
  static bool get desviaNoPrimeiroAviso => confirmacoesParaBloquear <= 1;

  /// Tempo que um aviso da comunidade fica ativo. Cada confirmação renova.
  static const duracaoOcorrencia = Duration(hours: 4);
}
