// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/app_theme.dart';
import 'settings_provider.dart';
import 'widgets/settings_error_view.dart';
import 'widgets/settings_content.dart';

// FIX (Engineer): removed `export 'settings_provider.dart'` — a screen file
// must not serve as a barrel exporter for its own provider. Consumers that
// need SettingsState / SettingsNotifier must import settings_provider.dart
// directly to avoid implicit transitive exposure of internal types.

// ============================================================================
// SETTINGS SCREEN
// ============================================================================
//
// CHANGES:
//   • SettingsSkeletonLoader removed as a body state — the screen no longer
//     freezes entirely during loading. Only the ProfileCard shimmer appears
//     inside SettingsContent while status == loading; tiles are immediately
//     usable.
//   • export directive removed — screens are not barrels.

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor:                    Colors.transparent,
        statusBarIconBrightness:           isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:               isDark ? Brightness.dark  : Brightness.light,
        systemNavigationBarColor:          Colors.transparent,
        systemNavigationBarDividerColor:   Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
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

          // Full error view — no content to show at all.
          SettingsStatus.error => SettingsErrorView(
              errorMessage: state.errorMessage,
              onRetry: () => ref.read(settingsProvider.notifier).retry(),
            ),

          // Loading OR idle: always render SettingsContent.
          // The ProfileCard inside SettingsContent handles its own shimmer
          // while status == loading, so tiles are immediately usable.
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

// ============================================================================
// PRIVATE — FULL-SCREEN BLOCKING OVERLAY
// Shown during sign-out and account deletion. Lightweight: no skeleton, no
// list rebuild — just a scrim with a spinner.
// ============================================================================

class _FullScreenOverlay extends StatelessWidget {
  const _FullScreenOverlay();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('common.loading'),
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
