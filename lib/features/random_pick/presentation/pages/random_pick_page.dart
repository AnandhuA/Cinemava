import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../movies/domain/entities/movie.dart';
import '../../../movies/presentation/providers/movie_library_provider.dart';
import '../providers/spin_wheel_provider.dart';

class RandomPickPage extends StatefulWidget {
  const RandomPickPage({super.key});

  @override
  State<RandomPickPage> createState() => _RandomPickPageState();
}

class _RandomPickPageState extends State<RandomPickPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _spinAnimation;
  final _random = math.Random();
  double _rotation = 0;
  Movie? _selectedMovie;
  Timer? _spinSoundTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _spinAnimation = AlwaysStoppedAnimation(_rotation);
  }

  @override
  void dispose() {
    _spinSoundTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<MovieLibraryProvider>();
    final wheel = context.watch<SpinWheelProvider>();
    final wheelMovies = wheel.movies;
    _seedWheel(library.trending);

    return Scaffold(
      appBar: AppBar(title: const Text('Random Pick')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _spinAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _spinAnimation.value,
                      child: child,
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _WheelPosterSegments(movies: wheelMovies),
                            CustomPaint(
                              painter: _WheelOverlayPainter(wheelMovies),
                              child: const SizedBox.expand(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: Icon(
                    Icons.movie_filter_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: !wheel.canSpin || _controller.isAnimating
                ? null
                : () => _spin(wheelMovies),
            icon: const Icon(Icons.rotate_right),
            label: const Text('Spin'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed:
                library.availableMovies.isEmpty || _controller.isAnimating
                ? null
                : () => _refreshRandomMovies(library, wheel),
            icon: const Icon(Icons.shuffle),
            label: const Text('Random all time'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: wheel.isFull
                ? null
                : () => _showAddMoviesSheet(library, wheel),
            icon: const Icon(Icons.add),
            label: const Text('Add movies'),
          ),
          const SizedBox(height: 8),
          Text(
            '${wheelMovies.length}/${SpinWheelProvider.maxMovies} movies • minimum ${SpinWheelProvider.minMovies} to spin',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_selectedMovie != null) ...[
            const SizedBox(height: 20),
            _PickedMovieCard(movie: _selectedMovie!),
          ],
          const SizedBox(height: 24),
          Text(
            'On the wheel',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (wheelMovies.isEmpty)
            const Text('Add movies to start spinning.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final movie in wheelMovies)
                  InputChip(
                    label: Text(movie.title),
                    onDeleted: () {
                      wheel.removeMovie(movie.id);
                      if (_selectedMovie?.id == movie.id || !wheel.canSpin) {
                        setState(() => _selectedMovie = null);
                      }
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _seedWheel(List<Movie> movies) {
    if (movies.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SpinWheelProvider>().seed(movies);
    });
  }

  void _spin(List<Movie> movies) {
    final segmentAngle = (math.pi * 2) / movies.length;
    final selectedIndex = _random.nextInt(movies.length);
    final targetAngle = -math.pi / 2 - (selectedIndex + 0.5) * segmentAngle;
    final fullSpins = (5 + _random.nextInt(3)) * math.pi * 2;
    final endRotation = fullSpins + targetAngle;
    final spinMovies = List<Movie>.from(movies);

    _spinAnimation = Tween<double>(
      begin: _rotation,
      end: endRotation,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _startSpinSound();
    _controller.reset();
    _controller.forward().whenComplete(() {
      _stopSpinSound();
      SystemSound.play(SystemSoundType.click);
      setState(() {
        _rotation = endRotation % (math.pi * 2);
        _selectedMovie = _movieAtPointer(spinMovies, _rotation);
      });
    });
    setState(() {});
  }

  Movie _movieAtPointer(List<Movie> movies, double rotation) {
    final segmentAngle = (math.pi * 2) / movies.length;
    final pointerAngle = _normalizeAngle(-math.pi / 2 - rotation);
    final wheelStart = _normalizeAngle(pointerAngle + math.pi / 2);
    final index = (wheelStart / segmentAngle).floor().clamp(
      0,
      movies.length - 1,
    );
    return movies[index];
  }

  double _normalizeAngle(double angle) {
    final fullCircle = math.pi * 2;
    return ((angle % fullCircle) + fullCircle) % fullCircle;
  }

  void _refreshRandomMovies(
    MovieLibraryProvider library,
    SpinWheelProvider wheel,
  ) {
    final movies = wheel.refreshRandomMovies(library.availableMovies);
    setState(() => _selectedMovie = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          movies.isEmpty
              ? 'No loaded movies available yet.'
              : 'Spin wheel refreshed with random movies.',
        ),
      ),
    );
  }

  void _startSpinSound() {
    _spinSoundTimer?.cancel();
    SystemSound.play(SystemSoundType.click);
    _spinSoundTimer = Timer.periodic(const Duration(milliseconds: 170), (_) {
      SystemSound.play(SystemSoundType.click);
    });
  }

  void _stopSpinSound() {
    _spinSoundTimer?.cancel();
    _spinSoundTimer = null;
  }

  void _showAddMoviesSheet(
    MovieLibraryProvider library,
    SpinWheelProvider wheel,
  ) {
    final available = library.availableMovies
        .where((movie) => !wheel.contains(movie.id))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return available.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No more loaded movies to add.'),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: available.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final movie = available[index];
                  return ListTile(
                    leading: movie.posterUrl.isEmpty
                        ? const Icon(Icons.movie_outlined)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              movie.posterUrl,
                              width: 42,
                              height: 58,
                              fit: BoxFit.cover,
                            ),
                          ),
                    title: Text(movie.title),
                    subtitle: Text('${movie.year} • ${movie.language}'),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () {
                      final added = wheel.addMovie(movie);
                      if (added) setState(() => _selectedMovie = null);
                      Navigator.of(context).pop();
                      if (!added && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Spin wheel is full. Remove a movie first.',
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
      },
    );
  }
}

class _WheelPosterSegments extends StatelessWidget {
  const _WheelPosterSegments({required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF252936),
        child: Center(child: Icon(Icons.movie_outlined, size: 46)),
      );
    }

    return LayoutBuilder(
      builder: (_, _) {
        final sweepAngle = (math.pi * 2) / movies.length;
        return Stack(
          fit: StackFit.expand,
          children: [
            for (var index = 0; index < movies.length; index++)
              ClipPath(
                clipper: _WheelSegmentClipper(
                  startAngle: -math.pi / 2 + index * sweepAngle,
                  sweepAngle: sweepAngle,
                ),
                child: _PosterSegmentImage(movie: movies[index]),
              ),
          ],
        );
      },
    );
  }
}

class _PosterSegmentImage extends StatelessWidget {
  const _PosterSegmentImage({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    if (movie.posterUrl.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF252936),
        child: Icon(Icons.movie_outlined, color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(movie.posterUrl, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black12, Colors.black45],
            ),
          ),
        ),
      ],
    );
  }
}

class _WheelSegmentClipper extends CustomClipper<Path> {
  const _WheelSegmentClipper({
    required this.startAngle,
    required this.sweepAngle,
  });

  final double startAngle;
  final double sweepAngle;

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    return Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, startAngle, sweepAngle, false)
      ..close();
  }

  @override
  bool shouldReclip(covariant _WheelSegmentClipper oldClipper) {
    return oldClipper.startAngle != startAngle ||
        oldClipper.sweepAngle != sweepAngle;
  }
}

class _PickedMovieCard extends StatelessWidget {
  const _PickedMovieCard({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/movie/${movie.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Hero(
                tag: 'movie-poster-${movie.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: movie.posterUrl.isEmpty
                      ? const SizedBox(
                          width: 72,
                          height: 108,
                          child: ColoredBox(
                            color: Color(0xFF252936),
                            child: Icon(Icons.movie_outlined),
                          ),
                        )
                      : Image.network(
                          movie.posterUrl,
                          width: 72,
                          height: 108,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tonight pick',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${movie.year} • ${movie.language}'),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelOverlayPainter extends CustomPainter {
  const _WheelOverlayPainter(this.movies);

  final List<Movie> movies;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white70;

    if (movies.isEmpty) {
      canvas.drawCircle(center, radius, borderPaint);
      return;
    }

    final segmentAngle = (math.pi * 2) / movies.length;
    final dividerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white70;

    for (var index = 0; index < movies.length; index++) {
      final startAngle = -math.pi / 2 + index * segmentAngle;
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(startAngle) * radius,
          center.dy + math.sin(startAngle) * radius,
        ),
        dividerPaint,
      );

      final title = movies[index].title;
      final label = title.length > 16 ? '${title.substring(0, 15)}...' : title;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * 0.62);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + segmentAngle / 2);
      canvas.translate(radius * 0.26, -textPainter.height / 2);
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(-6, -4, textPainter.width + 12, textPainter.height + 8),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        labelRect,
        Paint()..color = Colors.black.withValues(alpha: 0.48),
      );
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelOverlayPainter oldDelegate) {
    return true;
  }
}
