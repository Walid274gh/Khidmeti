// lib/screens/settings/widgets/settings_error_view.dart
//
// FIX [C2]: wrapped ElevatedButton.icon in a Center + SizedBox with a fixed
//           width (AppConstants.splashRetryButtonMinWidth = 120dp) so the
//           button does not stretch full-width in the centered error layout.
// FIX [W2]: replaced error.withOpacity(0.6) with pre-baked AppTheme tokens
//           (darkErrorMuted / lightErrorMuted) — inline opacity contract violation.
// FIX [W3/C12]: replaced size: 64 with AppConstants.iconSizeLg2 (64.0) — the new
//           mid-scale icon token that fills the gap between iconSizeXl (48) and
//           iconSizeHero (80).
// FIX [W8]: replaced splashRetryButtonMinWidth * 1.5 arithmetic with the named
//           token AppConstants.settingsRetryButtonWidth (180.0). Arithmetic in
//           layout code is a code smell — the resolved value (180dp) is now a
//           single source of truth.
// FIX [MANUAL-A11Y]: removed redundant outer Semantics(label:, button: true)
//           wrapper around the ElevatedButton.icon. ElevatedButton already
//           exposes its own semantics node with the correct role and label derived
//           from its child Text. Wrapping it in an additional Semantics node
//           creates a duplicate a11y surface, causing screen readers to announce
//           the action twice. The SizedBox constraint is preserved; only the
//           Semantics wrapper is removed.

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class SettingsErrorView extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const SettingsErrorView({
    super.key,
    required this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayMessage = errorMessage != null
        ? context.tr(errorMessage!)
        : context.tr('errors.unknown');

    // Pre-baked opacity token — no inline .withOpacity().
    final iconColor = isDark ? AppTheme.darkErrorMuted : AppTheme.lightErrorMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.error,
              // [C12]: iconSizeLg2 = 64.0 — mid-scale between iconSizeXl (48)
              // and iconSizeHero (80). Appropriate for in-content error states.
              size:  AppConstants.iconSizeLg2,
              color: iconColor,
            ),
            const SizedBox(height: AppConstants.paddingMd),
            Text(
              context.tr('common.error'),
              style:     theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              displayMessage,
              style:     theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            // [W8]: settingsRetryButtonWidth = 180dp replaces the arithmetic
            // splashRetryButtonMinWidth * 1.5. The global ElevatedButton theme
            // sets minimumSize: Size(double.infinity, 54) which would otherwise
            // cause this button to stretch full-width inside the centered column.
            //
            // [MANUAL-A11Y]: outer Semantics(label:, button: true) wrapper
            // removed — ElevatedButton already carries its own semantics node.
            // The duplicate wrapper caused TalkBack/VoiceOver to announce the
            // retry action twice. SizedBox constraint is preserved as-is.
            SizedBox(
              width: AppConstants.settingsRetryButtonWidth,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon:      const Icon(Icons.refresh_rounded),
                label:     Text(context.tr('common.retry')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
