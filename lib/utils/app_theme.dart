// lib/utils/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_enums.dart';

/// ============================================================
/// 🎨 KHIDMETI APP THEME — Midnight Indigo v2.0
/// ============================================================

class AppTheme {
  // ==========================================================
  // 🎨 CORE PALETTE — DARK THEME
  // ==========================================================

  static const Color darkBackground     = Color(0xFF080510);
  static const Color darkSurface        = Color(0xFF141028);
  static const Color darkSurfaceVariant = Color(0xFF1C1235);
  static const Color darkDeepBackground = Color(0xFF120820);
  static const Color darkText           = Color(0xFFF0EAFF);
  static const Color darkSecondaryText  = Color(0xFF7A6E96);
  static const Color darkTertiaryText   = Color(0xFF4A4260);
  static const Color darkAccent         = Color(0xFF4F46E5);
  static const Color darkBorder         = Color(0xFF221640);
  static const Color darkError          = Color(0xFFF87171);
  static const Color darkSuccess        = Color(0xFF34D399);
  static const Color darkWarning        = Color(0xFFFBBF24);

  // ==========================================================
  // 🎨 CORE PALETTE — LIGHT THEME
  // ==========================================================

  static const Color lightBackground    = Color(0xFFF8F7FF);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant= Color(0xFFF0EEFF);
  static const Color lightText          = Color(0xFF12041C);
  static const Color lightSecondaryText = Color(0xFF6B64A0);
  static const Color lightTertiaryText  = Color(0xFFA8A2D4);
  static const Color lightAccent        = Color(0xFF4F46E5);
  static const Color lightBorder        = Color(0xFFE0DBFF);
  static const Color lightError         = Color(0xFFDC2626);
  static const Color lightSuccess       = Color(0xFF16A34A);
  static const Color lightWarning       = Color(0xFFD97706);

  // ==========================================================
  // 🎨 NEW TOKENS — added per upgrade plan
  // ==========================================================

  /// Dark surface for the WhatsApp contact button.
  static const Color whatsAppDarkSurface = Color(0xFF1B2B1B);

  /// Semantic overlay border for cards in light mode.
  static const Color lightCardBorderOverlay = Color(0x12000000);

  /// Semantic overlay border for cards in dark mode.
  static const Color darkCardBorderOverlay = Color(0x12FFFFFF);

  // FIX (README3): named token for text shadow on ProfileCard.
  static const List<Shadow> profileCardTextShadow = [
    Shadow(
      color: Color(0xAA000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // FIX (README5 Designer): dedicated tokens for HomePromoSection.
  static const Color promoBlueDark  = Color(0xFF60A5FA);
  static const Color promoBlueLight = Color(0xFF2563EB);

  // FIX (README5 WCAG AA): improved contrast token for body text on darkBackground.
  static const Color darkSecondaryTextWcag = Color(0xFF9B91C0);

  // ==========================================================
  // 🎨 WHATSAPP TOKENS — [MANUAL FIX]
  // ==========================================================

  /// WhatsApp brand green — used for outlined button border/foreground
  /// and the fallback icon background.
  /// Replaces hardcoded `Color(0xFF25D366)` in whatsapp_button.dart.
  static const Color whatsAppGreen = Color(0xFF25D366);

  /// WhatsApp dark teal — used for the filled button background.
  /// Provides sufficient contrast for white icon/text on top.
  /// Replaces hardcoded `Color(0xFF128C7E)` in whatsapp_button.dart.
  static const Color whatsAppDark = Color(0xFF128C7E);

  // ==========================================================
  // 🎨 FEATURE / KEPT COLOURS
  // ==========================================================

  static const Color aiPrimary          = Color(0xFF6C47FF);
  static const Color warningOrange      = Color(0xFFFB923C);
  static const Color onlineGreen        = Color(0xFF22C55E);
  static const Color recordingRed       = Color(0xFFF44336);
  static const Color iconPink           = Color(0xFFEC4899);
  static const Color signOutRed         = Color(0xFFEF4444);
  static const Color iconViolet         = Color(0xFF8B5CF6);
  static const Color iconEmerald        = Color(0xFF10B981);
  static const Color iconIndigo         = Color(0xFF6366F1);
  static const Color priorityNormalDark = Color(0xFF34D399);
  static const Color warningAmber       = Color(0xFFFBBF24);
  static const Color cyanBlue           = Color(0xFF06B6D4);
  static const Color acceptGreen        = Color(0xFF16A34A);
  static const Color darkAuthHeroTop    = Color(0xFF120820);

  // ==========================================================
  // 🎨 STATUS COLOURS
  // ==========================================================

  static const Color statusAcceptedDark    = Color(0xFF60A5FA);
  static const Color statusAcceptedLight   = Color(0xFF2563EB);
  static const Color statusInProgressDark  = Color(0xFFA78BFA);
  static const Color statusInProgressLight = Color(0xFF7C3AED);
  static const Color statusCancelledDark   = Color(0xFFF87171);

  // ==========================================================
  // 🎨 PROFESSION COLOURS
  // ==========================================================

  static const Color professionPlumberDark          = Color(0xFF60A5FA);
  static const Color professionPlumberLight         = Color(0xFF2563EB);
  static const Color professionPainterDark          = Color(0xFFA78BFA);
  static const Color professionPainterLight         = Color(0xFF7C3AED);
  static const Color professionCarpenterDark        = Color(0xFFF87171);
  static const Color professionGardenerDark         = Color(0xFF4ADE80);
  static const Color professionAcRepairLight        = Color(0xFF0891B2);
  static const Color professionApplianceRepairLight = Color(0xFFEA580C);

  // ==========================================================
  // 🎨 DISABLED STATE
  // ==========================================================

  static const Color disabledFill   = Color(0x1A9E9E9E);
  static const Color disabledBorder = Color(0x339E9E9E);

  // ==========================================================
  // 🌑 DARK THEME
  // ==========================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness:   Brightness.dark,
      colorScheme: const ColorScheme.dark(
        brightness:              Brightness.dark,
        primary:                 darkAccent,
        onPrimary:               darkBackground,
        secondary:               darkAccent,
        onSecondary:             darkBackground,
        surface:                 darkSurface,
        onSurface:               darkText,
        surfaceContainerLowest:  darkBackground,
        error:                   darkError,
        onError:                 Colors.black,
        surfaceContainerHighest: darkSurfaceVariant,
        outline:                 darkBorder,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardTheme(
        elevation:   0,
        color:       darkSurface,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 0.5),
        ),
        margin: const EdgeInsets.all(8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkError.withOpacity(0.8), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkError, width: 1.5),
        ),
        labelStyle: const TextStyle(color: darkSecondaryText, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        floatingLabelStyle: const TextStyle(color: darkAccent, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: darkSecondaryText.withOpacity(0.6), fontFamily: 'Inter'),
        contentPadding:  const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        prefixIconColor: darkSecondaryText,
        suffixIconColor: darkSecondaryText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: darkBackground,
          elevation:       0,
          minimumSize:     const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkAccent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          side: BorderSide(color: darkBorder.withOpacity(0.2), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation:              0,
        scrolledUnderElevation: 0,
        backgroundColor:        darkBackground.withOpacity(0.8),
        foregroundColor:        darkText,
        centerTitle:            true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: const TextStyle(color: darkText, fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Inter', letterSpacing: -0.3),
        iconTheme:        const IconThemeData(color: darkAccent, size: 24),
        actionsIconTheme: const IconThemeData(color: darkText),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      darkSurface,
        selectedItemColor:    darkAccent,
        unselectedItemColor:  darkSecondaryText,
        type:                 BottomNavigationBarType.fixed,
        elevation:            0,
        selectedLabelStyle:   const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurface,
        contentTextStyle: const TextStyle(color: darkText, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkBorder.withOpacity(0.2)),
        ),
        behavior:     SnackBarBehavior.floating,
        elevation:    0,
        insetPadding: const EdgeInsets.all(16),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: darkBorder.withOpacity(0.2), width: 0.5),
        ),
        titleTextStyle:   const TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
        contentTextStyle: const TextStyle(color: darkSecondaryText, fontSize: 15, fontFamily: 'Inter'),
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: darkText, fontFamily: 'Inter', letterSpacing: -1.5),
        displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: darkText, fontFamily: 'Inter', letterSpacing: -1),
        displaySmall:  TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: darkText, fontFamily: 'Inter', letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: darkText, fontFamily: 'Inter', letterSpacing: -1.2, height: 1.02),
        headlineMedium:TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: darkText, fontFamily: 'Inter', letterSpacing: -0.6),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkText, fontFamily: 'Inter', letterSpacing: -0.3),
        titleLarge:    TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: darkText, fontFamily: 'Inter'),
        titleMedium:   TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: darkText, fontFamily: 'Inter'),
        titleSmall:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkSecondaryText, fontFamily: 'Inter'),
        bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: darkText, fontFamily: 'Inter', height: 1.6),
        bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: darkText, fontFamily: 'Inter', height: 1.6),
        bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: darkSecondaryText, fontFamily: 'Inter', height: 1.5),
        labelLarge:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText, fontFamily: 'Inter'),
        labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkSecondaryText, fontFamily: 'Inter'),
        labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: darkText, fontFamily: 'Inter', letterSpacing: 0.10),
      ),
      dividerTheme: DividerThemeData(color: darkBorder.withOpacity(0.2), thickness: 1, space: 24),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor:     darkSurfaceVariant,
        selectedColor:       darkAccent.withOpacity(0.2),
        labelStyle:          const TextStyle(color: darkText, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        secondaryLabelStyle: const TextStyle(color: darkAccent, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: darkBorder.withOpacity(0.2)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (s) => s.contains(WidgetState.selected) ? darkAccent : darkSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (s) => s.contains(WidgetState.selected)
              ? darkAccent.withOpacity(0.5)
              : darkSurfaceVariant.withOpacity(0.5),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor:   darkAccent,
        inactiveTrackColor: darkSurfaceVariant,
        thumbColor:         darkAccent,
        overlayColor:       darkAccent.withOpacity(0.2),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:              darkAccent,
        circularTrackColor: darkSurfaceVariant,
        linearTrackColor:   darkSurfaceVariant,
      ),
    );
  }

  // ==========================================================
  // ☀️ LIGHT THEME
  // ==========================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness:   Brightness.light,
      colorScheme: const ColorScheme.light(
        brightness:              Brightness.light,
        primary:                 lightAccent,
        onPrimary:               lightBackground,
        secondary:               lightAccent,
        onSecondary:             lightBackground,
        surface:                 lightSurface,
        onSurface:               lightText,
        error:                   lightError,
        onError:                 Colors.white,
        surfaceContainerHighest: lightSurfaceVariant,
        outline:                 lightBorder,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardTheme: CardTheme(
        elevation:   0,
        color:       lightSurface,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder, width: 0.5),
        ),
        margin: const EdgeInsets.all(8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightError.withOpacity(0.8), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightError, width: 1.5),
        ),
        labelStyle:          const TextStyle(color: lightSecondaryText, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        floatingLabelStyle:  const TextStyle(color: lightAccent, fontWeight: FontWeight.w600),
        hintStyle:           TextStyle(color: lightSecondaryText.withOpacity(0.7), fontFamily: 'Inter'),
        contentPadding:      const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        prefixIconColor:     lightSecondaryText,
        suffixIconColor:     lightSecondaryText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightAccent,
          foregroundColor: lightBackground,
          elevation:       0,
          minimumSize:     const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightAccent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightText,
          side: const BorderSide(color: lightBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation:              0,
        scrolledUnderElevation: 0,
        backgroundColor:        lightBackground.withOpacity(0.9),
        foregroundColor:        lightText,
        centerTitle:            true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle:   const TextStyle(color: lightText, fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Inter', letterSpacing: -0.3),
        iconTheme:        const IconThemeData(color: lightAccent, size: 24),
        actionsIconTheme: const IconThemeData(color: lightText),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      lightSurface,
        selectedItemColor:    lightAccent,
        unselectedItemColor:  lightSecondaryText,
        type:                 BottomNavigationBarType.fixed,
        elevation:            0,
        selectedLabelStyle:   const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightText,
        contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior:     SnackBarBehavior.floating,
        elevation:    4,
        insetPadding: const EdgeInsets.all(16),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: lightBorder, width: 0.5),
        ),
        titleTextStyle:   const TextStyle(color: lightText, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
        contentTextStyle: const TextStyle(color: lightSecondaryText, fontSize: 15, fontFamily: 'Inter'),
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: lightText, fontFamily: 'Inter', letterSpacing: -1.5),
        displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: lightText, fontFamily: 'Inter', letterSpacing: -1),
        displaySmall:  TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: lightText, fontFamily: 'Inter', letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: lightText, fontFamily: 'Inter', letterSpacing: -1.2, height: 1.02),
        headlineMedium:TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: lightText, fontFamily: 'Inter', letterSpacing: -0.6),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: lightText, fontFamily: 'Inter', letterSpacing: -0.3),
        titleLarge:    TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: lightText, fontFamily: 'Inter'),
        titleMedium:   TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: lightText, fontFamily: 'Inter'),
        titleSmall:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: lightSecondaryText, fontFamily: 'Inter'),
        bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: lightText, fontFamily: 'Inter', height: 1.6),
        bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: lightText, fontFamily: 'Inter', height: 1.6),
        bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: lightSecondaryText, fontFamily: 'Inter', height: 1.5),
        labelLarge:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: lightText, fontFamily: 'Inter'),
        labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: lightSecondaryText, fontFamily: 'Inter'),
        labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lightText, fontFamily: 'Inter', letterSpacing: 0.10),
      ),
      dividerTheme:     const DividerThemeData(color: lightBorder, thickness: 1, space: 24),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor:     lightSurfaceVariant,
        selectedColor:       lightAccent.withOpacity(0.15),
        labelStyle:          const TextStyle(color: lightText, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        secondaryLabelStyle: const TextStyle(color: lightAccent, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: lightBorder, width: 0.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (s) => s.contains(WidgetState.selected) ? lightAccent : lightSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (s) => s.contains(WidgetState.selected) ? lightAccent.withOpacity(0.5) : lightBorder,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor:   lightAccent,
        inactiveTrackColor: lightBorder,
        thumbColor:         lightAccent,
        overlayColor:       lightAccent.withOpacity(0.2),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:              lightAccent,
        circularTrackColor: lightSurfaceVariant,
        linearTrackColor:   lightSurfaceVariant,
      ),
    );
  }

  // ==========================================================
  // 🎨 HELPER METHODS
  // ==========================================================

  static Color getProfessionColor(String profession, bool isDark) =>
      isDark ? darkAccent : lightAccent;

  static Color getStatusColor(ServiceStatus status, bool isDark) {
    switch (status) {
      case ServiceStatus.open:
      case ServiceStatus.pending:
        return isDark ? darkAccent.withOpacity(0.80) : lightAccent.withOpacity(0.80);
      case ServiceStatus.awaitingSelection:
        return isDark ? darkWarning : lightWarning;
      case ServiceStatus.bidSelected:
      case ServiceStatus.accepted:
        return isDark ? darkAccent : lightAccent;
      case ServiceStatus.inProgress:
        return isDark ? darkAccent : lightAccent;
      case ServiceStatus.completed:
        return isDark ? darkSuccess : lightSuccess;
      case ServiceStatus.cancelled:
      case ServiceStatus.declined:
      case ServiceStatus.expired:
        return isDark ? darkSecondaryText : lightSecondaryText;
    }
  }

  static IconData getProfessionIcon(String serviceType) {
    const map = <String, IconData>{
      'plumber':          Icons.plumbing_rounded,
      'electrician':      Icons.electrical_services_rounded,
      'cleaner':          Icons.cleaning_services_rounded,
      'painter':          Icons.format_paint_rounded,
      'carpenter':        Icons.carpenter_rounded,
      'mason':            Icons.domain_rounded,
      'ac_repair':        Icons.air_rounded,
      'gardener':         Icons.grass_rounded,
      'appliance_repair': Icons.kitchen_rounded,
    };
    return map[serviceType] ?? Icons.work_outline_rounded;
  }
}
