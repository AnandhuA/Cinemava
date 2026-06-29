import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/router/app_router.dart';
import '../app/theme/app_theme.dart';
import '../app/theme/theme_provider.dart';
import '../features/journal/presentation/providers/journal_provider.dart';
import '../features/movies/presentation/providers/movie_library_provider.dart';

class CinemavaApp extends StatelessWidget {
  const CinemavaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MovieLibraryProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
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
}
