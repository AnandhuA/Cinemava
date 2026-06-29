import 'package:flutter/widgets.dart';

class Responsive {
  const Responsive._();

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 700;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;

  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1180;
    if (isTablet(context)) return 900;
    return double.infinity;
  }

  static int posterGridCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 6;
    if (width >= 900) return 5;
    if (width >= 600) return 4;
    return 2;
  }

  static double posterGridAspectRatio(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 0.54;
    if (width >= 600) return 0.53;
    return 0.52;
  }

  static double movieRailHeight(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 292;
    if (width >= 600) return 276;
    return 248;
  }

  static double movieRailCardWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 164;
    if (width >= 600) return 152;
    return 136;
  }

  static double spacing(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 24;
    if (width >= 600) return 20;
    return 16;
  }
}
