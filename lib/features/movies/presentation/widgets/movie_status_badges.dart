import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/movie_library_provider.dart';

class MovieStatusBadges extends StatelessWidget {
  const MovieStatusBadges({
    super.key,
    required this.movieId,
    this.dense = false,
  });

  final int movieId;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<MovieLibraryProvider>();
    final isWatched = library.isWatched(movieId);
    final isSaved = library.isInWatchlist(movieId);
    if (!isWatched && !isSaved) return const SizedBox.shrink();

    return SizedBox(
      height: dense ? 48 : 58,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (isWatched)
            Align(
              alignment: Alignment.topLeft,
              child: _CornerRibbon(
                label: dense ? 'WATCHED' : 'SEEN',
                color: Colors.green.withValues(alpha: 0.6),
                alignment: Alignment.topLeft,
                size: dense ? 48 : 58,
              ),
            ),
          if (isSaved)
            Align(
              alignment: isWatched ? Alignment.topRight : Alignment.topLeft,
              child: _CornerRibbon(
                label: dense ? 'SAVED' : 'WATCHLIST',
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.6),
                alignment: isWatched ? Alignment.topRight : Alignment.topLeft,
                size: dense ? 48 : 58,
              ),
            ),
        ],
      ),
    );
  }
}

class _CornerRibbon extends StatelessWidget {
  const _CornerRibbon({
    required this.label,
    required this.color,
    required this.alignment,
    required this.size,
  });

  final String label;
  final Color color;
  final Alignment alignment;
  final double size;

  bool get _isLeft => alignment == Alignment.topLeft;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          ClipPath(
            clipper: _CornerRibbonClipper(isLeft: _isLeft),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: _isLeft ? Alignment.topLeft : Alignment.topRight,
                  end: _isLeft ? Alignment.bottomRight : Alignment.bottomLeft,
                  colors: [color.withValues(alpha: 0.98), color],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: size * 0.22,
            left: _isLeft ? -size * 0.22 : null,
            right: _isLeft ? null : -size * 0.22,
            width: size * 1.15,
            child: Transform.rotate(
              angle: _isLeft ? -0.785398 : 0.785398,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.clip,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontSize: size < 52 ? 8 : 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          Positioned(
            top: size * 0.72,
            left: _isLeft ? 0 : null,
            right: _isLeft ? null : 0,
            child: CustomPaint(
              size: Size(size * 0.28, size * 0.28),
              painter: _FoldShadowPainter(
                color: Colors.black.withValues(alpha: 0.18),
                isLeft: _isLeft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerRibbonClipper extends CustomClipper<Path> {
  const _CornerRibbonClipper({required this.isLeft});

  final bool isLeft;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (isLeft) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(0, size.height)
        ..close();
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, 0)
        ..close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _CornerRibbonClipper oldClipper) {
    return oldClipper.isLeft != isLeft;
  }
}

class _FoldShadowPainter extends CustomPainter {
  const _FoldShadowPainter({required this.color, required this.isLeft});

  final Color color;
  final bool isLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isLeft) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FoldShadowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isLeft != isLeft;
  }
}
