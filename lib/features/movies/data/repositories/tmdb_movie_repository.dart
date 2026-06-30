import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/movie_details.dart';
import '../../domain/entities/movie.dart';
import '../models/tmdb_movie_dto.dart';

class TmdbMovieRepository {
  TmdbMovieRepository(this._dio, [this._cacheBox]);

  final Dio _dio;
  final Box<dynamic>? _cacheBox;

  Future<List<Movie>> trending() => _getMovies('/trending/movie/day');
  Future<List<Movie>> popular() => _getMovies('/movie/popular');
  Future<List<Movie>> topRated() => _getMovies('/movie/top_rated');
  Future<List<Movie>> upcoming() => _getMovies('/movie/upcoming');
  Future<List<Movie>> cachedPopular() =>
      _getMovies('/movie/popular', cacheOnly: true);
  Future<List<Movie>> cachedTopRated() =>
      _getMovies('/movie/top_rated', cacheOnly: true);
  Future<List<Movie>> cachedUpcoming() =>
      _getMovies('/movie/upcoming', cacheOnly: true);

  Future<List<Movie>> search(String query) {
    return _getMovies('/search/movie', extraParams: {'query': query});
  }

  Future<List<Movie>> moviesByLanguage(String language) {
    final languageCode = _languageCodes[language];
    if (languageCode == null) return Future.value(const []);

    return _getMovies(
      '/discover/movie',
      extraParams: {
        'sort_by': 'popularity.desc',
        'with_original_language': languageCode,
      },
    );
  }

  Future<MovieDetails> movieDetails(Movie movie) async {
    try {
      final detail = await _getMap(
        '/movie/${movie.id}',
        extraParams: {
          'append_to_response':
              'credits,videos,watch/providers,recommendations',
        },
      );
      final credits = _nestedMap(detail, 'credits');
      final videos = _nestedMap(detail, 'videos');
      final providers = _nestedMap(detail, 'watch/providers');
      final recommendations = _moviesFromResults(
        _nestedMap(detail, 'recommendations'),
      );

      return MovieDetails(
        movie: movie,
        runtime: _formatRuntime(detail['runtime'] as int?),
        cast: _castFromCredits(credits),
        trailerUrl: _trailerUrlFromVideos(videos),
        streamingProviders: _providersFromWatchProviders(providers),
        recommendations: recommendations.take(12).toList(),
      );
    } on DioException catch (error) {
      _logDioError(
        path: '/movie/${movie.id}',
        authMode: 'details',
        error: error,
      );
      throw TmdbNetworkException(_friendlyDioMessage(error));
    }
  }

  Future<List<Movie>> _getMovies(
    String path, {
    Map<String, dynamic> extraParams = const {},
    bool cacheOnly = false,
  }) async {
    try {
      final response = await _getMap(
        path,
        extraParams: extraParams,
        cacheOnly: cacheOnly,
      );

      return _moviesFromResults(response);
    } on DioException catch (error) {
      _logDioError(path: path, authMode: 'movies', error: error);
      throw TmdbNetworkException(_friendlyDioMessage(error));
    }
  }

  Future<Map<String, dynamic>> _getMap(
    String path, {
    Map<String, dynamic> extraParams = const {},
    bool cacheOnly = false,
  }) async {
    final queryParameters = _queryParameters(extraParams);
    final cacheKey = _cacheKey(path, queryParameters);
    final cached = _cachedResponse(cacheKey);
    if (cached != null) {
      _log('CACHE HIT $path');
      return cached;
    }

    if (cacheOnly) {
      final stale = _cachedResponse(cacheKey, allowStale: true);
      if (stale != null) {
        _log('CACHE STALE HIT $path');
        return stale;
      }
      throw const TmdbCacheMissException('No cached TMDb data available yet.');
    }

    try {
      _ensureCredentials();
      final response = await _getMapRemoteWithRetry(
        path,
        extraParams: extraParams,
      );
      final data = response.data ?? <String, dynamic>{};
      await _writeCachedResponse(cacheKey, data);
      return data;
    } on DioException catch (_) {
      final stale = _cachedResponse(cacheKey, allowStale: true);
      if (stale != null) {
        _log('CACHE STALE FALLBACK $path');
        return stale;
      }
      rethrow;
    } on TmdbConfigurationException {
      final stale = _cachedResponse(cacheKey, allowStale: true);
      if (stale != null) {
        _log('CACHE STALE FALLBACK $path');
        return stale;
      }
      rethrow;
    }
  }

  Future<Response<Map<String, dynamic>>> _getMapRemoteWithRetry(
    String path, {
    Map<String, dynamic> extraParams = const {},
  }) async {
    const maxAttempts = 2;
    DioException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _getMapRemote(path, extraParams: extraParams);
      } on DioException catch (error) {
        lastError = error;
        if (attempt == maxAttempts || !_shouldRetry(error)) rethrow;
        _log('RETRY $path after ${error.type}');
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
    }

    throw lastError!;
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.unknown;
  }

  List<Movie> _moviesFromResults(Map<String, dynamic> response) {
    final results = response['results'] as List<dynamic>? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(TmdbMovieDto.fromJson)
        .where((movie) => movie.id != 0)
        .map((movie) => movie.toEntity())
        .toList();
  }

  Map<String, dynamic> _nestedMap(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is Map) return _stringKeyedMap(value);
    return <String, dynamic>{};
  }

  Future<Response<Map<String, dynamic>>> _getMapRemote(
    String path, {
    Map<String, dynamic> extraParams = const {},
  }) async {
    if (ApiConstants.tmdbApiKey.isNotEmpty) {
      try {
        return await _getMapWithApiKey(path, extraParams: extraParams);
      } on DioException catch (error) {
        _logDioError(path: path, authMode: 'api_key', error: error);
        if (ApiConstants.tmdbReadAccessToken.isEmpty) rethrow;
        final statusCode = error.response?.statusCode;
        if (statusCode != 401 && statusCode != 403) rethrow;
        _log('Falling back to read access token for $path');
      }
    }

    return await _getMapWithReadAccessToken(path, extraParams: extraParams);
  }

  Future<Response<Map<String, dynamic>>> _getMapWithApiKey(
    String path, {
    Map<String, dynamic> extraParams = const {},
  }) async {
    final queryParameters = {
      'api_key': ApiConstants.tmdbApiKey,
      ..._queryParameters(extraParams),
    };
    _logRequest(path: path, authMode: 'api_key', params: queryParameters);

    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}$path',
      queryParameters: queryParameters,
    );
    _logResponse(path: path, authMode: 'api_key', response: response);
    return response;
  }

  Future<Response<Map<String, dynamic>>> _getMapWithReadAccessToken(
    String path, {
    Map<String, dynamic> extraParams = const {},
  }) async {
    final queryParameters = _queryParameters(extraParams);
    _logRequest(
      path: path,
      authMode: 'read_access_token',
      params: queryParameters,
    );

    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}$path',
      queryParameters: queryParameters,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${ApiConstants.tmdbReadAccessToken}',
        },
      ),
    );
    _logResponse(path: path, authMode: 'read_access_token', response: response);
    return response;
  }

  List<CastMember> _castFromCredits(Map<String, dynamic> response) {
    final cast = response['cast'] as List<dynamic>? ?? const [];
    return cast
        .whereType<Map<String, dynamic>>()
        .take(12)
        .map(
          (item) => CastMember(
            name: item['name'] as String? ?? 'Unknown',
            character: item['character'] as String? ?? '',
            profileUrl: item['profile_path'] == null
                ? ''
                : '${ApiConstants.tmdbImageBaseUrl}${item['profile_path']}',
          ),
        )
        .toList();
  }

  String? _trailerUrlFromVideos(Map<String, dynamic> response) {
    final videos = response['results'] as List<dynamic>? ?? const [];
    final youtubeVideos = videos.whereType<Map<String, dynamic>>().where(
      (item) => item['site'] == 'YouTube',
    );

    Map<String, dynamic>? trailer;
    for (final video in youtubeVideos) {
      if (video['type'] == 'Trailer' && video['official'] == true) {
        trailer = video;
        break;
      }
    }
    trailer ??= youtubeVideos.isEmpty ? null : youtubeVideos.first;

    final key = trailer?['key'] as String?;
    if (key == null || key.isEmpty) return null;
    return 'https://www.youtube.com/watch?v=$key';
  }

  List<WatchProvider> _providersFromWatchProviders(
    Map<String, dynamic> response,
  ) {
    final results = response['results'] as Map<String, dynamic>? ?? {};
    final country = (results['IN'] ?? results['US']) as Map<String, dynamic>?;
    final flatrate = country?['flatrate'] as List<dynamic>? ?? const [];

    return flatrate
        .whereType<Map<String, dynamic>>()
        .map(
          (provider) => WatchProvider(
            name: provider['provider_name'] as String? ?? 'Streaming',
            logoUrl: provider['logo_path'] == null
                ? ''
                : '${ApiConstants.tmdbImageBaseUrl}${provider['logo_path']}',
          ),
        )
        .toList();
  }

  String _formatRuntime(int? minutes) {
    if (minutes == null || minutes <= 0) return '-';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '${remainingMinutes}m';
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  void _ensureCredentials() {
    final hasReadAccessToken = ApiConstants.tmdbReadAccessToken.isNotEmpty;
    final hasApiKey = ApiConstants.tmdbApiKey.isNotEmpty;

    if (!hasReadAccessToken && !hasApiKey) {
      throw const TmdbConfigurationException(
        'Missing TMDb credentials. Add tmdbReadAccessToken in ApiConstants or run with --dart-define=TMDB_READ_ACCESS_TOKEN=your_token',
      );
    }
  }

  Map<String, dynamic> _queryParameters(Map<String, dynamic> extraParams) {
    return {'language': 'en-US', 'page': 1, ...extraParams};
  }

  String _cacheKey(String path, Map<String, dynamic> queryParameters) {
    final entries = queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final query = entries
        .map((entry) => '${entry.key}=${Uri.encodeComponent('${entry.value}')}')
        .join('&');
    return 'tmdb:$path?$query';
  }

  Map<String, dynamic>? _cachedResponse(
    String cacheKey, {
    bool allowStale = false,
  }) {
    final cached = _cacheBox?.get(cacheKey);
    if (cached is! Map) return null;

    final savedAt = DateTime.tryParse(cached['savedAt']?.toString() ?? '');
    if (!allowStale && !_isToday(savedAt)) return null;

    final data = cached['data'];
    if (data is Map) return _stringKeyedMap(data);
    return null;
  }

  Future<void> _writeCachedResponse(
    String cacheKey,
    Map<String, dynamic> data,
  ) async {
    await _cacheBox?.put(cacheKey, {
      'savedAt': DateTime.now().toIso8601String(),
      'data': data,
    });
  }

  bool _isToday(DateTime? value) {
    if (value == null) return false;
    return _dateKey(value.toLocal()) == _dateKey(DateTime.now());
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> source) {
    return source.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _stringKeyedMap(value));
      }
      if (value is List) {
        return MapEntry(key.toString(), _normalizeList(value));
      }
      return MapEntry(key.toString(), value);
    });
  }

  List<dynamic> _normalizeList(List<dynamic> source) {
    return source.map((value) {
      if (value is Map) return _stringKeyedMap(value);
      if (value is List) return _normalizeList(value);
      return value;
    }).toList();
  }

  String _friendlyDioMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return 'TMDb rejected the credentials. Check the API read access token in ApiConstants.';
    }
    if (statusCode != null) {
      return 'TMDb request failed with status $statusCode.';
    }

    return 'Could not connect to TMDb. Check your connection and try again.';
  }

  void _logRequest({
    required String path,
    required String authMode,
    required Map<String, dynamic> params,
  }) {
    final safeParams = Map<String, dynamic>.from(params);
    if (safeParams.containsKey('api_key')) {
      safeParams['api_key'] = _maskSecret(safeParams['api_key'].toString());
    }
    _log(
      'REQUEST $authMode ${ApiConstants.tmdbBaseUrl}$path params=$safeParams',
    );
  }

  void _logResponse({
    required String path,
    required String authMode,
    required Response<Map<String, dynamic>> response,
  }) {
    final results = response.data?['results'];
    final resultCount = results is List ? results.length : null;
    _log(
      'RESPONSE $authMode $path status=${response.statusCode} results=$resultCount',
    );
  }

  void _logDioError({
    required String path,
    required String authMode,
    required DioException error,
  }) {
    _log(
      'ERROR $authMode $path type=${error.type} status=${error.response?.statusCode} message=${error.message} error=${error.error}',
    );
  }

  String _maskSecret(String value) {
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }

  void _log(String message) {
    debugPrint('[TMDB] $message');
  }
}

class TmdbConfigurationException implements Exception {
  const TmdbConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TmdbNetworkException implements Exception {
  const TmdbNetworkException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TmdbCacheMissException implements Exception {
  const TmdbCacheMissException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _languageCodes = {
  'English': 'en',
  'Hindi': 'hi',
  'Malayalam': 'ml',
  'Tamil': 'ta',
  'Telugu': 'te',
  'Kannada': 'kn',
};
