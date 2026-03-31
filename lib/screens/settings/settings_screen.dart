// lib/screens/settings/settings_screen.dart
//
// CHANGE: settings_provider.dart import updated from local path to lib/providers/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/app_theme.dart';
import '../../utils/system_ui_overlay.dart'; // NEW
import '../../providers/settings_provider.dart'; // CHANGED: was './settings_provider.dart'
import 'widgets/settings_error_view.dart';
import 'widgets/settings_content.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark), // REPLACED inline block
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor:        Colors.transparent,
          elevation:              0,
          scrolledUnderElevation: 0,
          title: Text(
            context.tr('settings.title'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: true,
          automaticallyImplyLeading: context.canPop(),
          leading: context.canPop()
              ? Semantics(
                  label: context.tr('common.back'),
                  child: IconButton(
                    icon:     const Icon(AppIcons.back),
                    onPressed: () => context.pop(),
                    tooltip:  context.tr('common.back'),
                  ),
                )
              : null,
        ),
        body: switch (state.status) {
          SettingsStatus.error => SettingsErrorView(
              errorMessage: state.errorMessage,
              onRetry: () => ref.read(settingsProvider.notifier).retry(),
            ),
          _ => Stack(
              children: [
                SettingsContent(state: state),
                if (state.isSigningOut || state.isDeletingAccount)
                  const _FullScreenOverlay(),
              ],
            ),
        },
      ),
    );
  }
}

class _FullScreenOverlay extends StatelessWidget {
  const _FullScreenOverlay();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:      context.tr('common.loading'),
      liveRegion: true,
      child: Container(
        color: Theme.of(context).colorScheme.scrim.withOpacity(0.35),
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
