// lib/screens/settings/widgets/settings_error_view.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class SettingsErrorView extends StatelessWidget {
  // FIX — errorMessage was populated by SettingsNotifier but this widget
  // always displayed context.tr('errors.unknown'), ignoring the specific key.
  // Added optional errorMessage parameter forwarded from SettingsState.
  final String? errorMessage;
  final VoidCallback onRetry;

  const SettingsErrorView({
    super.key,
    required this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use the specific error key from state if available, fall back to generic.
    final displayMessage = errorMessage != null
        ? context.tr(errorMessage!)
        : context.tr('errors.unknown');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.error,
              size: 64,
              color: theme.colorScheme.error.withOpacity(0.6),
            ),
            const SizedBox(height: AppConstants.paddingMd),
            Text(
              context.tr('common.error'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              displayMessage,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Semantics(
              label: context.tr('common.retry'),
              button: true,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('common.retry')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

