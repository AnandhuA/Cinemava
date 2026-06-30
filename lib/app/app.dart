import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../app/router/app_router.dart';
import '../app/theme/app_theme.dart';
import '../app/theme/theme_provider.dart';
import '../features/journal/presentation/providers/journal_provider.dart';
import '../features/movies/data/repositories/tmdb_movie_repository.dart';
import '../features/movies/presentation/providers/movie_library_provider.dart';
import '../features/onboarding/presentation/providers/user_preference_provider.dart';
import '../features/random_pick/presentation/providers/spin_wheel_provider.dart';

class CinemavaApp extends StatelessWidget {
  const CinemavaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(
            Hive.isBoxOpen('user_preferences')
                ? Hive.box('user_preferences')
                : null,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UserPreferenceProvider(
            Hive.isBoxOpen('user_preferences')
                ? Hive.box('user_preferences')
                : null,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MovieLibraryProvider(
            TmdbMovieRepository(
              _createDio(),
              Hive.isBoxOpen('tmdb_cache') ? Hive.box('tmdb_cache') : null,
            ),
            Hive.isBoxOpen('movie_library') ? Hive.box('movie_library') : null,
          )..loadInitialMovies(),
        ),
        ChangeNotifierProvider(
          create: (_) => JournalProvider(
            Hive.isBoxOpen('journal') ? Hive.box('journal') : null,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SpinWheelProvider(
            Hive.isBoxOpen('spin_wheel') ? Hive.box('spin_wheel') : null,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Cinemava',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme(themeProvider.accentColor),
            darkTheme: AppTheme.darkTheme(themeProvider.accentColor),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }

  Dio _createDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {'accept': 'application/json'},
      ),
    );
  }
}
