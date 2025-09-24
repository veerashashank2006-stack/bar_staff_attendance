import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A class that contains all theme configurations for the employee attendance management application.
class AppTheme {
  AppTheme._();

  // Color specifications based on Dark-First Professional design theme
  static const Color primary =
      Color(0xFF00E0C0); // Neon-teal for primary actions and focus states
  static const Color secondary =
      Color(0xFF1A1A1A); // Deep charcoal for primary backgrounds
  static const Color surface =
      Color(0xFF2A2A2A); // Elevated surface color for cards and modals
  static const Color background =
      Color(0xFF121212); // True dark background following Material Design
  static const Color onPrimary =
      Color(0xFF000000); // High contrast text on primary color
  static const Color onSurface =
      Color(0xFFFFFFFF); // Primary text color on dark surfaces
  static const Color onBackground =
      Color(0xFFE0E0E0); // Secondary text color with 87% opacity
  static const Color error =
      Color(0xFFFF5252); // Material Design error red, optimized for dark theme
  static const Color success =
      Color(0xFF4CAF50); // Confirmation green for successful actions
  static const Color warning =
      Color(0xFFFFC107); // Amber for caution states and pending status

  // Additional colors for comprehensive theming
  static const Color surfaceVariant = Color(0xFF3A3A3A);
  static const Color outline = Color(0xFF4A4A4A);
  static const Color shadow = Color(0x33000000); // 20% opacity black shadows
  static const Color scrim = Color(0x80000000);

  // Text emphasis colors
  static const Color textHighEmphasis = Color(0xDEFFFFFF); // 87% opacity
  static const Color textMediumEmphasis = Color(0x99FFFFFF); // 60% opacity
  static const Color textDisabled = Color(0x61FFFFFF); // 38% opacity

  /// Dark theme (primary theme for the application)
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primary.withAlpha(51),
      onPrimaryContainer: primary,
      secondary: surface,
      onSecondary: onSurface,
      secondaryContainer: surfaceVariant,
      onSecondaryContainer: onSurface,
      tertiary: warning,
      onTertiary: onPrimary,
      tertiaryContainer: warning.withAlpha(51),
      onTertiaryContainer: warning,
      error: error,
      onError: onPrimary,
      errorContainer: error.withAlpha(51),
      onErrorContainer: error,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: textMediumEmphasis,
      outline: outline,
      outlineVariant: outline.withAlpha(128),
      shadow: shadow,
      scrim: scrim,
      inverseSurface: onSurface,
      onInverseSurface: surface,
      inversePrimary: primary,
      surfaceTint: primary,
    ),
    scaffoldBackgroundColor: background,
    cardColor: surface,
    dividerColor: outline,

    // AppBar theme with glassmorphism effect
    appBarTheme: AppBarTheme(
      backgroundColor: surface.withAlpha(230),
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 4,
      shadowColor: shadow,
      surfaceTintColor: primary,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0.15,
      ),
      iconTheme: const IconThemeData(
        color: onSurface,
        size: 24,
      ),
      actionsIconTheme: const IconThemeData(
        color: onSurface,
        size: 24,
      ),
    ),

    // Card theme with subtle elevation
    cardTheme: CardTheme(
      color: surface,
      elevation: 4,
      shadowColor: shadow,
      surfaceTintColor: primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.all(8.0),
    ),

    // Bottom navigation theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textMediumEmphasis,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
    ),

    // Floating Action Button with gradient effect
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 8,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimary,
        backgroundColor: primary,
        elevation: 2,
        shadowColor: shadow,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: const BorderSide(color: primary, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),

    // Text theme using Inter font family
    textTheme: _buildTextTheme(),

    // Input decoration theme with clean borders
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surface,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: outline, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: outline, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: textMediumEmphasis,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: textDisabled,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: GoogleFonts.inter(
        color: error,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return textMediumEmphasis;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary.withAlpha(128);
        }
        return outline;
      }),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(onPrimary),
      side: const BorderSide(color: outline, width: 2),
    ),

    // Radio theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return outline;
      }),
    ),

    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: outline,
      circularTrackColor: outline,
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: primary,
      thumbColor: primary,
      overlayColor: primary.withAlpha(51),
      inactiveTrackColor: outline,
      valueIndicatorColor: primary,
      valueIndicatorTextStyle: GoogleFonts.inter(
        color: onPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Tab bar theme
    tabBarTheme: TabBarTheme(
      labelColor: primary,
      unselectedLabelColor: textMediumEmphasis,
      indicatorColor: primary,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.25,
      ),
    ),

    // Tooltip theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: onSurface.withAlpha(230),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: GoogleFonts.inter(
        color: surface,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    // SnackBar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: onSurface,
      contentTextStyle: GoogleFonts.inter(
        color: surface,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 6,
    ),

    // Dialog theme
    dialogTheme: DialogTheme(
      backgroundColor: surface,
      surfaceTintColor: primary,
      elevation: 8,
      shadowColor: shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      titleTextStyle: GoogleFonts.inter(
        color: onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: textMediumEmphasis,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),

    // List tile theme
    listTileTheme: ListTileThemeData(
      tileColor: surface,
      selectedTileColor: primary.withAlpha(26),
      iconColor: textMediumEmphasis,
      selectedColor: primary,
      textColor: onSurface,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      subtitleTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textMediumEmphasis,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariant,
      selectedColor: primary.withAlpha(51),
      disabledColor: outline,
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textMediumEmphasis,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    ),
  );

  /// Light theme (fallback theme)
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primary.withAlpha(26),
      onPrimaryContainer: primary,
      secondary: const Color(0xFFF5F5F5),
      onSecondary: const Color(0xFF1A1A1A),
      secondaryContainer: const Color(0xFFE0E0E0),
      onSecondaryContainer: const Color(0xFF1A1A1A),
      tertiary: warning,
      onTertiary: onPrimary,
      tertiaryContainer: warning.withAlpha(26),
      onTertiaryContainer: warning,
      error: error,
      onError: Colors.white,
      errorContainer: error.withAlpha(26),
      onErrorContainer: error,
      surface: Colors.white,
      onSurface: const Color(0xFF1A1A1A),
      onSurfaceVariant: const Color(0xFF666666),
      outline: const Color(0xFFCCCCCC),
      outlineVariant: const Color(0xFFE0E0E0),
      shadow: const Color(0x1A000000),
      scrim: const Color(0x80000000),
      inverseSurface: const Color(0xFF1A1A1A),
      onInverseSurface: Colors.white,
      inversePrimary: primary,
      surfaceTint: primary,
    ),
    scaffoldBackgroundColor: Colors.white,
    // Additional light theme configurations would follow the same pattern
    textTheme: _buildTextTheme(isLight: true),
  );

  /// Helper method to build text theme using Inter font family
  static TextTheme _buildTextTheme({bool isLight = false}) {
    final Color textColor = isLight ? const Color(0xFF1A1A1A) : onSurface;
    final Color textColorMedium =
        isLight ? const Color(0xFF666666) : textMediumEmphasis;
    final Color textColorDisabled =
        isLight ? const Color(0xFF999999) : textDisabled;

    return TextTheme(
      // Display styles - Inter with appropriate weights
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),

      // Headline styles - Inter with w400, w600, w700
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),

      // Title styles - Inter with w400, w500
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.1,
      ),

      // Body styles - Inter with w300, w400, w500
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColorMedium,
        letterSpacing: 0.4,
      ),

      // Label styles - Inter with w400, w500
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColorMedium,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColorDisabled,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Data text style using JetBrains Mono for timestamps, employee IDs, and numerical data
  static TextStyle dataTextStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    bool isLight = false,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? (isLight ? const Color(0xFF1A1A1A) : onSurface),
      letterSpacing: 0.25,
    );
  }

  /// Caption text style using Inter for small text elements
  static TextStyle captionTextStyle({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    bool isLight = false,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? (isLight ? const Color(0xFF666666) : textMediumEmphasis),
      letterSpacing: 0.4,
    );
  }

  /// Box shadow for cards with 4dp blur radius and 20% opacity
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadow,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Box shadow for floating elements
  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: shadow,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
}
