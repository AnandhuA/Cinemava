import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/movie_details.dart';
import '../../domain/entities/movie.dart';
import '../models/tmdb_movie_dto.dart';

class TmdbMovieRepository {
  TmdbMovieRepository(this._dio);

  final Dio _dio;

  Future<List<Movie>> trending() => _getMovies('/trending/movie/day');
  Future<List<Movie>> popular() => _getMovies('/movie/popular');
  Future<List<Movie>> topRated() => _getMovies('/movie/top_rated');
  Future<List<Movie>> upcoming() => _getMovies('/movie/upcoming');

  Future<List<Movie>> search(String query) {
    return _getMovies('/search/movie', extraParams: {'query': query});
  }

  Future<MovieDetails> movieDetails(Movie movie) async {
    try {
      final detail = await _getMap('/movie/${movie.id}');
      final credits = await _getMap('/movie/${movie.id}/credits');
      final videos = await _getMap('/movie/${movie.id}/videos');
      final providers = await _getMap('/movie/${movie.id}/watch/providers');
      final recommendations = await _getMovies(
        '/movie/${movie.id}/recommendations',
      );

      return MovieDetails(
        movie: movie,
        runtime: _formatRuntime(detail.data?['runtime'] as int?),
        cast: _castFromCredits(credits),
        trailerUrl: _trailerUrlFromVideos(videos),
        streamingProviders: _providersFromWatchProviders(providers),
        recommendations: recommendations.take(12).toList(),
      );
    } on DioException catch (error) {
      throw TmdbNetworkException(_friendlyDioMessage(error));
    }
  }

  Future<List<Movie>> _getMovies(
    String path, {
    Map<String, dynamic> extraParams = const {},
  }) async {
    final hasReadAccessToken = ApiConstants.tmdbReadAccessToken.isNotEmpty;
    final hasApiKey = ApiConstants.tmdbApiKey.isNotEmpty;

    if (!hasReadAccessToken && !hasApiKey) {
      throw const TmdbConfigurationException(
        'Missing TMDb credentials. Add tmdbReadAccessToken in ApiConstants or run with --dart-define=TMDB_READ_ACCESS_TOKEN=your_token',
      );
    }

    try {
      final response = await _getMap(path, extraParams: extraParams);

      final results = response.data?['results'] as List<dynamic>? ?? const [];
      return results
          .whereType<Map<String, dynamic>>()
          .map(TmdbMovieDto.fromJson)
          .where((movie) => movie.id != 0)
          .map((movie) => movie.toEntity())
          .toList();
    } on DioException catch (error) {
      throw TmdbNetworkException(_friendlyDioMessage(error));
    }
  }

  Future<Response<Map<String, dynamic>>> _getMap(
    String path, {
    Map<String, dynamic> extraParams = const {},
  }) async {
    if (ApiConstants.tmdbApiKey.isNotEmpty) {
      try {
        return _getMapWithApiKey(path, extraParams: extraParams);
      } on DioException catch (error) {
        if (ApiConstants.tmdbReadAccessToken.isEmpty) rethrow;
        final statusCode = error.response?.statusCode;
        if (statusCode != 401 && statusCode != 403) rethrow;
      }
    }

    return _getMapWithReadAccessToken(path, extraParams: extraParams);
  }

  Future<Response<Map<String, dynamic>>> _getMapWithApiKey(
    String path, {
    Map<String, dynamic> extraParams = const {},
  }) {
    return _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}$path',
      queryParameters: {
        'api_key': ApiConstants.tmdbApiKey,
        'language': 'en-US',
        'page': 1,
        ...extraParams,
      },
    );
  }

  Future<Response<Map<String, dynamic>>> _getMapWithReadAccessToken(
    String path, {
    Map<String, dynamic> extraParams = const {},
  }) {
    return _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}$path',
      queryParameters: {'language': 'en-US', 'page': 1, ...extraParams},
      options: Options(
        headers: {
          'Authorization': 'Bearer ${ApiConstants.tmdbReadAccessToken}',
        },
      ),
    );
  }

  List<CastMember> _castFromCredits(Response<Map<String, dynamic>> response) {
    final cast = response.data?['cast'] as List<dynamic>? ?? const [];
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

  String? _trailerUrlFromVideos(Response<Map<String, dynamic>> response) {
    final videos = response.data?['results'] as List<dynamic>? ?? const [];
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
    Response<Map<String, dynamic>> response,
  ) {
    final results = response.data?['results'] as Map<String, dynamic>? ?? {};
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

  String _friendlyDioMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return 'TMDb rejected the credentials. Check the API read access token in ApiConstants.';
    }
    if (statusCode != null) {
      return 'TMDb request failed with status $statusCode.';
    }
    return 'Could not connect to api.themoviedb.org. Open that site in the same device browser, try Wi-Fi/VPN/private DNS off, then retry.';
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
