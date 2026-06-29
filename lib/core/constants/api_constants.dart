class ApiConstants {
  const ApiConstants._();

  static const _localTmdbApiKey = '5271ca46aa806c5c3737d89875256d20';
  static const _localTmdbReadAccessToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1MjcxY2E0NmFhODA2YzVjMzczN2Q4OTg3NTI1NmQyMCIsIm5iZiI6MTc4Mjc0ODMyNi43MTI5OTk4LCJzdWIiOiI2YTQyOTRhNjA1YjBkMzRkMjliZGNmZDMiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.UjXlQO4NOwMYKtmxH3bGW4O9F2tjnlyJKluVbTlJP8A';

  static const tmdbApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: _localTmdbApiKey,
  );

  static const tmdbReadAccessToken = String.fromEnvironment(
    'TMDB_READ_ACCESS_TOKEN',
    defaultValue: _localTmdbReadAccessToken,
  );

  static const tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const tmdbBackdropBaseUrl = 'https://image.tmdb.org/t/p/w1280';
}
