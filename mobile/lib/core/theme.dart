import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Rang palitrasi MedLink logotipidan olingan.
class Brand {
  static const blue = Color(0xFF055DBE);
  static const teal = Color(0xFF12AEAB);
  static const ink = Color(0xFF0E2340);
  static const danger = Color(0xFFD32F2F);
  static const warning = Color(0xFFEF6C00);
  static const success = Color(0xFF2E7D32);

  static const gradient = LinearGradient(
    colors: [blue, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// WCAG kontrast nisbati (1..21).
double contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

/// [color] ni [background] ustida o'qiladigan qiladi: tus saqlanadi, yorqinlik
/// WCAG AA (matn uchun 4.5:1) ga yetguncha o'zgartiriladi. Brend ranglari
/// (masalan, yashil-moviy #12AEAB) oq fonda matn uchun yetarli kontrast
/// bermaydi — shu funksiya orqali matn rangi avtomatik to'qlashtiriladi.
Color readableOn(Color color, Color background, {double minRatio = 4.5}) {
  var hsl = HSLColor.fromColor(color);
  final darken = background.computeLuminance() > 0.4;
  for (
    var i = 0;
    i < 50 && contrastRatio(hsl.toColor(), background) < minRatio;
    i++
  ) {
    hsl = hsl.withLightness(
      (hsl.lightness + (darken ? -0.02 : 0.02)).clamp(0.0, 1.0),
    );
  }
  return hsl.toColor();
}

/// Kontekstga bog'liq ranglar (yorug'/qorong'i rejim).
extension AppColors on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Kartochka foni ustidagi matn uchun o'qiladigan rang.
  Color ink(Color c) => readableOn(c, colors.surface);

  /// Shaffof tusli fon ([alpha]) ustidagi matn uchun o'qiladigan rang.
  Color inkOnTint(Color c, double alpha) => readableOn(
    c,
    Color.alphaBlend(c.withValues(alpha: alpha), colors.surface),
  );

  /// "Animatsiyani kamaytirish" sozlamasi yoqilgan bo'lsa — animatsiyasiz.
  Duration motion(Duration d) =>
      MediaQuery.disableAnimationsOf(this) ? Duration.zero : d;
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Brand.blue,
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFF6FA8FF) : Brand.blue,
        secondary: Brand.teal,
        surface: dark ? const Color(0xFF111D2E) : Colors.white,
        surfaceContainerLowest: dark
            ? const Color(0xFF0B1626)
            : const Color(0xFFF4F7FB),
        error: Brand.danger,
      );
  final border = dark ? const Color(0xFF22324A) : const Color(0xFFE3E9F2);
  final radius = BorderRadius.circular(14);

  // Tipografiya (UI/UX Pro Max: "medical, clean, accessible"): sarlavhalar
  // Figtree, matn Noto Sans. Figtree'da kirill va ʻ (U+02BB) yo'q — ular
  // Noto Sans'dan olinadi, shuning uchun ruscha ham to'g'ri ko'rinadi.
  final base =
      (dark ? Typography.material2021().white : Typography.material2021().black)
          .apply(fontFamily: 'NotoSans');
  TextStyle? display(TextStyle? t) => t?.copyWith(
    fontFamily: 'Figtree',
    fontFamilyFallback: const ['NotoSans'],
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  final textTheme = base.copyWith(
    displayLarge: display(base.displayLarge),
    displayMedium: display(base.displayMedium),
    displaySmall: display(base.displaySmall),
    headlineLarge: display(base.headlineLarge),
    headlineMedium: display(base.headlineMedium),
    headlineSmall: display(base.headlineSmall),
    titleLarge: display(base.titleLarge),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: 'NotoSans',
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    // iOS'da Cupertino uslubidagi o'tishlar va "orqaga surish" ishlaydi.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontFamily: 'Figtree',
        fontFamilyFallback: const ['NotoSans'],
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border),
      ),
    ),
    dividerTheme: DividerThemeData(color: border, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: radius),
        side: BorderSide(color: border),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    // Tanlangan chip: yengil fon + rangli chegara (yorug' va qorong'i
    // rejimda ham matn kontrasti saqlanadi).
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selectedColor: scheme.primary.withValues(alpha: dark ? 0.28 : 0.14),
      side: WidgetStateBorderSide.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? BorderSide(color: scheme.primary, width: 1.5)
            : BorderSide(color: border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
