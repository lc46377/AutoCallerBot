import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData get themeLight {
  final base = ThemeData.light(useMaterial3: true);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4),
    brightness: Brightness.light,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    scaffoldBackgroundColor: colorScheme.background,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

// Helper for a subtle blue/purple gradient background
BoxDecoration gradientBackground(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary.withOpacity(0.08),
        scheme.secondary.withOpacity(0.08),
      ],
    ),
  );
}


// Alias to support newer call sites
BoxDecoration gradientBg(BuildContext context) {
  return gradientBackground(context);
}


