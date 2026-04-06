// lib/screens/settings/settings_screen.dart
//
// CHANGE: settings_provider.dart import updated from local path to lib/providers/.
// FIX [W11]: replaced colorScheme.scrim.withOpacity(0.35) with AppTheme.overlayScrim35
//            — the pre-baked 35% black overlay token added to app_theme.dart.
// FIX [W7]:  removed explicit Scaffold.backgroundColor isDark ternary.
//            The active ThemeData already sets scaffoldBackgroundColor correctly
//            (darkTheme → darkBackground, lightTheme → lightBackground).
//            Hardcoding it here was redundant and bypassed the single source of
//            truth in the theme. Removing it lets the theme drive the value.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/app_theme.dart';
import '../../utils/system_ui_overlay.dart';
import '../../providers/settings_provider.dart';
import 'widgets/settings_error_view.dart';
import 'widgets/settings_content.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        // FIX [W7]: backgroundColor removed — the active ThemeData already
        // provides the correct scaffoldBackgroundColor for each brightness.
        // Hardcoding the ternary here was redundant and bypassed the theme.
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
        // overlayScrim35 = Color(0x59000000) — black at 35% opacity.
        color: AppTheme.overlayScrim35,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
