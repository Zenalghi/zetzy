import 'package:material_ui/material_ui.dart';
import 'package:zetzy/l10n/app_localizations.dart';

/// Four visual skins specified in PRD Section 1.1.
enum ZetzyThemeMode {
  oledMidnight('oled_midnight'),
  classicWood('classic_wood'),
  nordicFrost('nordic_frost'),
  draculaNeon('dracula_neon');

  const ZetzyThemeMode(this.id);
  final String id;

  static ZetzyThemeMode fromId(String id) => ZetzyThemeMode.values.firstWhere(
    (t) => t.id == id,
    orElse: () => ZetzyThemeMode.oledMidnight,
  );

  String localizedName(AppLocalizations l10n) => switch (this) {
    ZetzyThemeMode.oledMidnight => l10n.themeOledMidnight,
    ZetzyThemeMode.classicWood => l10n.themeClassicWood,
    ZetzyThemeMode.nordicFrost => l10n.themeNordicFrost,
    ZetzyThemeMode.draculaNeon => l10n.themeDraculaNeon,
  };
}

/// Custom color & surface tokens for Tactile Modern Minimalist design.
@immutable
class ZetzyPalette extends ThemeExtension<ZetzyPalette> {
  const ZetzyPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.glassTint,
    required this.border,
    required this.accent,
    required this.accentSecondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.textPrimary,
    required this.textSecondary,
    required this.boardLight,
    required this.boardDark,
    required this.boardHighlight,
    required this.snakeHead,
    required this.snakeBody,
    required this.brightness,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color glassTint;
  final Color border;
  final Color accent;
  final Color accentSecondary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color textPrimary;
  final Color textSecondary;
  final Color boardLight;
  final Color boardDark;
  final Color boardHighlight;
  final Color snakeHead;
  final Color snakeBody;
  final Brightness brightness;

  @override
  ZetzyPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? glassTint,
    Color? border,
    Color? accent,
    Color? accentSecondary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? textPrimary,
    Color? textSecondary,
    Color? boardLight,
    Color? boardDark,
    Color? boardHighlight,
    Color? snakeHead,
    Color? snakeBody,
    Brightness? brightness,
  }) {
    return ZetzyPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      glassTint: glassTint ?? this.glassTint,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      boardLight: boardLight ?? this.boardLight,
      boardDark: boardDark ?? this.boardDark,
      boardHighlight: boardHighlight ?? this.boardHighlight,
      snakeHead: snakeHead ?? this.snakeHead,
      snakeBody: snakeBody ?? this.snakeBody,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  ZetzyPalette lerp(ThemeExtension<ZetzyPalette>? other, double t) {
    if (other is! ZetzyPalette) return this;
    return ZetzyPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      boardLight: Color.lerp(boardLight, other.boardLight, t)!,
      boardDark: Color.lerp(boardDark, other.boardDark, t)!,
      boardHighlight: Color.lerp(boardHighlight, other.boardHighlight, t)!,
      snakeHead: Color.lerp(snakeHead, other.snakeHead, t)!,
      snakeBody: Color.lerp(snakeBody, other.snakeBody, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

abstract final class ZetzyThemes {
  static const String uiFontFamily = 'PlusJakartaSans';
  static const String monoFontFamily = 'JetBrainsMono';

  static TextStyle monoStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) => TextStyle(
    fontFamily: monoFontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static ZetzyPalette paletteFor(ZetzyThemeMode mode) => switch (mode) {
    ZetzyThemeMode.oledMidnight => const ZetzyPalette(
      background: Color(0xFF0D0D0D),
      surface: Color(0xFF161618),
      surfaceElevated: Color(0xFF202024),
      glassTint: Color(0xCC121214),
      border: Color(0xFF2C2C32),
      accent: Color(0xFF4ADE80),
      accentSecondary: Color(0xFF38BDF8),
      success: Color(0xFF22C55E),
      warning: Color(0xFFF59E0B),
      danger: Color(0xFFEF4444),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFF94A3B8),
      boardLight: Color(0xFF2B2E36),
      boardDark: Color(0xFF1B1D22),
      boardHighlight: Color(0x554ADE80),
      snakeHead: Color(0xFF4ADE80),
      snakeBody: Color(0xFF16A34A),
      brightness: Brightness.dark,
    ),
    ZetzyThemeMode.classicWood => const ZetzyPalette(
      background: Color(0xFF221E1B),
      surface: Color(0xFF2D2722),
      surfaceElevated: Color(0xFF3A322B),
      glassTint: Color(0xCC26201B),
      border: Color(0xFF4F4339),
      accent: Color(0xFFE09F3E),
      accentSecondary: Color(0xFFD4A373),
      success: Color(0xFF6A994E),
      warning: Color(0xFFF4A261),
      danger: Color(0xFFBC4749),
      textPrimary: Color(0xFFFAF3E0),
      textSecondary: Color(0xFFCBBBA0),
      boardLight: Color(0xFFF0D9B5),
      boardDark: Color(0xFFB58863),
      boardHighlight: Color(0x66E09F3E),
      snakeHead: Color(0xFF8AB17D),
      snakeBody: Color(0xFF588157),
      brightness: Brightness.dark,
    ),
    ZetzyThemeMode.nordicFrost => const ZetzyPalette(
      background: Color(0xFFEEF3F8),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFE2EAF3),
      glassTint: Color(0xCCF1F5F9),
      border: Color(0xFFCBD5E1),
      accent: Color(0xFF2E6F95),
      accentSecondary: Color(0xFF5E81AC),
      success: Color(0xFF2A9D8F),
      warning: Color(0xFFD97706),
      danger: Color(0xFFDC2626),
      textPrimary: Color(0xFF1E293B),
      textSecondary: Color(0xFF64748B),
      boardLight: Color(0xFFE5ECF4),
      boardDark: Color(0xFF8CA6C1),
      boardHighlight: Color(0x552E6F95),
      snakeHead: Color(0xFF2E6F95),
      snakeBody: Color(0xFF5E81AC),
      brightness: Brightness.light,
    ),
    ZetzyThemeMode.draculaNeon => const ZetzyPalette(
      background: Color(0xFF191A24),
      surface: Color(0xFF242636),
      surfaceElevated: Color(0xFF2F3247),
      glassTint: Color(0xCC1E202E),
      border: Color(0xFF44475A),
      accent: Color(0xFF8BE9FD),
      accentSecondary: Color(0xFFBD93F9),
      success: Color(0xFF50FA7B),
      warning: Color(0xFFFFB86C),
      danger: Color(0xFFFF5555),
      textPrimary: Color(0xFFF8F8F2),
      textSecondary: Color(0xFFA9B1D6),
      boardLight: Color(0xFF44475A),
      boardDark: Color(0xFF282A36),
      boardHighlight: Color(0x66BD93F9),
      snakeHead: Color(0xFF8BE9FD),
      snakeBody: Color(0xFFBD93F9),
      brightness: Brightness.dark,
    ),
  };

  static ThemeData buildTheme(ZetzyThemeMode mode) {
    final p = paletteFor(mode);
    final isDark = p.brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: isDark ? Colors.black : Colors.white,
      secondary: p.accentSecondary,
      onSecondary: isDark ? Colors.black : Colors.white,
      error: p.danger,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
      surfaceContainerHighest: p.surfaceElevated,
      outline: p.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      fontFamily: uiFontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      cardColor: p.surface,
      dividerColor: p.border,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: uiFontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: uiFontFamily,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? p.accent : p.textSecondary,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.accent.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(color: p.accent),
        unselectedIconTheme: IconThemeData(color: p.textSecondary),
        selectedLabelTextStyle: TextStyle(
          fontFamily: uiFontFamily,
          fontWeight: FontWeight.w700,
          color: p.accent,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: uiFontFamily,
          fontWeight: FontWeight.w500,
          color: p.textSecondary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: isDark ? Colors.black : Colors.white,
          textStyle: const TextStyle(
            fontFamily: uiFontFamily,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 1.8),
        ),
      ),
    );
  }
}

extension ZetzyPaletteContext on BuildContext {
  ZetzyPalette get palette =>
      Theme.of(this).extension<ZetzyPalette>() ??
      ZetzyThemes.paletteFor(ZetzyThemeMode.oledMidnight);
}
