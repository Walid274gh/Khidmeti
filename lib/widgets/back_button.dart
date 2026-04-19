// lib/widgets/back_button.dart
//
// Universal back-navigation button used across all non-AppBar screens.
//
// Design: 48×48dp rounded-square icon button — Midnight Indigo design system.
//
// USAGE VARIANTS:
//
//   1. Standard (most screens):
//      AppBackButton(isDark: isDark)
//
//   2. With border (service-request form header):
//      AppBackButton(isDark: isDark, withBorder: true)
//
//   3. Form-step navigation (secondary color + border + custom action):
//      AppBackButton(
//        isDark: isDark,
//        withBorder: true,
//        useSecondaryColor: true,
//        onPressed: onBack,
//      )
//
//   4. Custom action (e.g. maybePop, go-router push):
//      AppBackButton(isDark: isDark, onPressed: () => context.go('/home'))
//
// NOTE: For AppBar / SliverAppBar leading slots, continue using the standard
// Material IconButton — it is already correct and consistent there.

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';

class AppBackButton extends StatelessWidget {
  /// Custom tap handler. When null, defaults to [Navigator.maybePop].
  final VoidCallback? onPressed;

  /// Explicit theme override. When null, reads from [Theme.of(context)].
  final bool? isDark;

  /// Renders a subtle border around the button.
  /// Use in the service-request form header and form-step navigation.
  final bool withBorder;

  /// Uses [AppTheme.darkSecondaryText] / [AppTheme.lightSecondaryText]
  /// for the icon colour instead of the primary text colour.
  /// Use in form-step navigation where the back arrow is de-emphasised.
  final bool useSecondaryColor;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.isDark,
    this.withBorder = false,
    this.useSecondaryColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;

    final iconColor = useSecondaryColor
        ? (dark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText)
        : (dark ? AppTheme.darkText : AppTheme.lightText);

    final bgColor =
        (dark ? Colors.white : Colors.black).withOpacity(0.07);

    final borderColor =
        (dark ? Colors.white : Colors.black).withOpacity(0.08);

    return Semantics(
      button: true,
      label: context.tr('common.back'),
      child: GestureDetector(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        child: Container(
          width: AppConstants.backButtonSize,   // 48dp
          height: AppConstants.backButtonSize,  // 48dp
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: withBorder
                ? Border.all(
                    color: borderColor,
                    width: AppConstants.borderWidthDefault,
                  )
                : null,
          ),
          child: Icon(
            AppIcons.back,
            size: 20,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
