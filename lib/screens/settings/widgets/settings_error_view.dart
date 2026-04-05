// lib/screens/settings/widgets/settings_error_view.dart
//
// FIX [C2]: wrapped ElevatedButton.icon in a Center + SizedBox with a fixed
//           width (AppConstants.splashRetryButtonMinWidth = 120dp) so the
//           button does not stretch full-width in the centered error layout.
//           The global ElevatedButton theme sets minimumSize: Size(double.infinity, 54)
//           which caused the button to fill the entire column width.
// FIX [W2]: replaced error.withOpacity(0.6) with pre-baked AppTheme tokens
//           (darkErrorMuted / lightErrorMuted) — inline opacity contract violation.
// FIX [W3]: replaced size: 64 with AppConstants.iconSizeLg2 (64.0) — the new
//           mid-scale icon token that fills the gap between iconSizeXl (48) and
//           iconSizeHero (80). 64dp is appropriate for in-content error states.

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

    // FIX [W2]: pre-baked opacity token — no inline .withOpacity().
    final iconColor = isDark ? AppTheme.darkErrorMuted : AppTheme.lightErrorMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.error,
              // FIX [W3]: size: 64 → AppConstants.iconSizeLg2 (64.0).
              size:  AppConstants.iconSizeLg2,
              // FIX [W2]: pre-baked muted error token replaces inline withOpacity.
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
            // FIX [C2]: constrain retry button — global theme sets
            // minimumSize: Size(double.infinity, 54) which made this
            // button stretch full-width inside the centered column.
            // SizedBox overrides that and gives it a sensible fixed width.
            Semantics(
              label:  context.tr('common.retry'),
              button: true,
              child: SizedBox(
                width: AppConstants.splashRetryButtonMinWidth * 1.5, // 180dp — comfortable tap target
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon:      const Icon(Icons.refresh_rounded),
                  label:     Text(context.tr('common.retry')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
