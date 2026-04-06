// lib/widgets/sheet_handle.dart
//
// Extracted from:
//   • lib/screens/auth/widgets/login_forgot_password_sheet.dart
//   • lib/screens/auth/widgets/profession_picker_sheet.dart
//
// Both sheets contained an identical inline handle indicator using raw
// width:40/height:4 literals and Colors.white/black.withOpacity() calls.
// This widget centralises the pattern and uses pre-baked AppTheme tokens.

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';

/// A drag handle indicator rendered at the top of bottom sheets.
///
/// Sized to [AppConstants.sheetHandleWidth] × [AppConstants.sheetHandleHeight]
/// (40 × 4 dp). Colour is resolved from the pre-baked
/// [AppTheme.sheetHandleDark] / [AppTheme.sheetHandleLight] tokens —
/// no inline `.withOpacity()` calls at the call site.
///
/// Usage:
/// ```dart
/// const SheetHandle()          // reads isDark from Theme automatically
/// SheetHandle(isDark: isDark)  // explicit override
/// ```
class SheetHandle extends StatelessWidget {
  /// When `null` (default) the widget reads [Brightness] from the ambient
  /// [Theme]. Pass an explicit value to override.
  final bool? isDark;

  const SheetHandle({super.key, this.isDark});

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width:  AppConstants.sheetHandleWidth,
        height: AppConstants.sheetHandleHeight,
        decoration: BoxDecoration(
          color: dark ? AppTheme.sheetHandleDark : AppTheme.sheetHandleLight,
          borderRadius: BorderRadius.circular(AppConstants.sheetHandleHeight / 2),
        ),
      ),
    );
  }
}
