import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/anime.dart';
import '../../domain/entities/anime_details.dart';
import '../models/jikan_anime_dto.dart';

class JikanAnimeRepository {
  JikanAnimeRepository(this._dio);

  final Dio _dio;

  Future<List<Anime>> topAnime() {
    return _getAnime('/top/anime', params: {'filter': 'bypopularity'});
  }

  Future<List<Anime>> searchAnime(String query) {
    return _getAnime('/anime', params: {'q': query, 'sfw': true});
  }

  Future<AnimeDetails> animeDetails(Anime fallback) async {
    try {
      final full = await _getMap('/anime/${fallback.id}/full');
      final characters = await _getMap('/anime/${fallback.id}/characters');
      final recommendations = await _animeRecommendations(fallback.id);

      final fullData = full.data?['data'] as Map<String, dynamic>? ?? {};
      final anime = fullData.isEmpty
          ? fallback
          : JikanAnimeDto.fromJson(fullData).toEntity();

      return AnimeDetails(
        anime: anime,
        trailerUrl: _trailerUrl(fullData),
        streamingLinks: _streamingLinks(fullData),
        characters: _characters(characters),
        recommendations: recommendations.take(12).toList(),
        status: fullData['status'] as String? ?? '',
        rating: fullData['rating'] as String? ?? '',
        duration: fullData['duration'] as String? ?? '',
      );
    } on DioException catch (error) {
      _log(
        'ERROR /anime/${fallback.id}/full type=${error.type} status=${error.response?.statusCode} message=${error.message} error=${error.error}',
      );
      throw JikanNetworkException(_friendlyMessage(error));
    }
  }

  Future<List<Anime>> _getAnime(
    String path, {
    Map<String, dynamic> params = const {},
  }) async {
    try {
      _log('REQUEST https://api.jikan.moe/v4$path params=$params');
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.jikan.moe/v4$path',
        queryParameters: {'page': 1, 'limit': 24, ...params},
      );
      final data = response.data?['data'] as List<dynamic>? ?? const [];
      _log(
        'RESPONSE $path status=${response.statusCode} results=${data.length}',
      );
      return data
          .whereType<Map<String, dynamic>>()
          .map(JikanAnimeDto.fromJson)
          .where((anime) => anime.id != 0 && anime.title.isNotEmpty)
          .map((anime) => anime.toEntity())
          .toList();
    } on DioException catch (error) {
      _log(
        'ERROR $path type=${error.type} status=${error.response?.statusCode} message=${error.message} error=${error.error}',
      );
      throw JikanNetworkException(_friendlyMessage(error));
    }
  }

  Future<List<Anime>> _animeRecommendations(int animeId) async {
    final response = await _getMap('/anime/$animeId/recommendations');
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((item) => item['entry'])
        .whereType<Map<String, dynamic>>()
        .map(JikanAnimeDto.fromJson)
        .where((anime) => anime.id != 0 && anime.title.isNotEmpty)
        .map((anime) => anime.toEntity())
        .toList();
  }

  Future<Response<Map<String, dynamic>>> _getMap(String path) async {
    _log('REQUEST https://api.jikan.moe/v4$path');
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.jikan.moe/v4$path',
    );
    _log('RESPONSE $path status=${response.statusCode}');
    return response;
  }

  String? _trailerUrl(Map<String, dynamic> fullData) {
    final trailer = fullData['trailer'] as Map<String, dynamic>? ?? {};
    final url = trailer['url'] as String?;
    if (url == null || url.isEmpty) return null;
    return url;
  }

  List<AnimeStreamingLink> _streamingLinks(Map<String, dynamic> fullData) {
    final streaming = fullData['streaming'] as List<dynamic>? ?? const [];
    return streaming
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => AnimeStreamingLink(
            name: item['name'] as String? ?? 'Streaming',
            url: item['url'] as String? ?? '',
          ),
        )
        .where((link) => link.url.isNotEmpty)
        .toList();
  }

  List<AnimeCharacter> _characters(Response<Map<String, dynamic>> response) {
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data.whereType<Map<String, dynamic>>().take(14).map((item) {
      final character = item['character'] as Map<String, dynamic>? ?? {};
      final images = character['images'] as Map<String, dynamic>? ?? {};
      final jpg = images['jpg'] as Map<String, dynamic>? ?? {};
      final voiceActors = item['voice_actors'] as List<dynamic>? ?? const [];
      final firstVoiceActor = voiceActors
          .whereType<Map<String, dynamic>>()
          .firstWhere(
            (actor) => actor['language'] == 'Japanese',
            orElse: () => const {},
          );
      final person = firstVoiceActor['person'] as Map<String, dynamic>?;

      return AnimeCharacter(
        name: character['name'] as String? ?? 'Unknown',
        role: item['role'] as String? ?? '',
        imageUrl: jpg['image_url'] as String? ?? '',
        voiceActorName: person?['name'] as String? ?? '',
      );
    }).toList();
  }

  String _friendlyMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 429) {
      return 'Jikan is rate limited right now. Please wait a moment and retry.';
    }
    if (statusCode != null) {
      return 'Jikan request failed with status $statusCode.';
    }
    final detail = error.error == null ? error.message : error.error.toString();
    return 'Could not connect to Jikan anime API. Reason: $detail';
  }

  void _log(String message) {
    debugPrint('[JIKAN] $message');
  }
}

class JikanNetworkException implements Exception {
  const JikanNetworkException(this.message);

  final String message;

  @override
  String toString() => message;
}
