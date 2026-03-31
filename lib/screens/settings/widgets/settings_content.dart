// lib/screens/settings/widgets/settings_content.dart
//
// CHANGE: settings_provider.dart import updated from '../settings_provider.dart'
//         to '../../../providers/settings_provider.dart'.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/core_providers.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/settings_provider.dart'; // CHANGED path
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/app_section_header.dart';
import '../../../widgets/glass_bottom_sheet.dart';
import '../../../widgets/shimmer_box.dart';
import 'profile_card.dart';
import 'settings_tile.dart';
import 'sheet_option.dart';
import 'sign_out_tile.dart';

class SettingsContent extends ConsumerWidget {
  final SettingsState state;

  const SettingsContent({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageService    = ref.watch(languageServiceProvider);
    final isActionInProgress = state.isSigningOut || state.isDeletingAccount;

    return ListView(
      padding: EdgeInsetsDirectional.only(
        top:    MediaQuery.of(context).padding.top + kToolbarHeight + 12,
        bottom: MediaQuery.of(context).padding.bottom +
            kBottomNavigationBarHeight +
            AppConstants.spacingLg,
        start:  AppConstants.paddingMd,
        end:    AppConstants.paddingMd,
      ),
      children: [
        if (state.status == SettingsStatus.loading)
          const _ProfileCardSkeleton()
        else
          ProfileCard(state: state),

        const SizedBox(height: AppConstants.spacingLg),

        AppSectionHeader(label: context.tr('settings.general')),
        const SizedBox(height: AppConstants.spacingSm),

        SettingsTile(
          icon:           AppIcons.language,
          iconColor:      AppTheme.cyanBlue,
          title:          context.tr('settings.language'),
          subtitle:       languageService.currentLanguageName,
          semanticsLabel: context.tr('settings.language'),
          onTap:          () => _showLanguageSheet(context, ref),
        ),

        SettingsTile(
          icon:           AppIcons.notifications,
          iconColor:      AppTheme.iconIndigo,
          title:          context.tr('settings.notifications'),
          semanticsLabel: context.tr('settings.notifications'),
          onTap:          () => context.push(AppRoutes.notifications),
        ),

        Consumer(
          builder: (context, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            return SettingsTile(
              icon:           AppIcons.theme,
              iconColor:      AppTheme.iconViolet,
              title:          context.tr('settings.theme'),
              subtitle:       _themeModeLabel(context, themeMode),
              semanticsLabel: context.tr('settings.theme'),
              onTap:          () => _showThemeSheet(context, ref, themeMode),
            );
          },
        ),

        const SizedBox(height: AppConstants.spacingMdLg),

        AppSectionHeader(label: context.tr('settings.account')),
        const SizedBox(height: AppConstants.spacingSm),

        SettingsTile(
          icon:           AppIcons.person,
          iconColor:      AppTheme.iconEmerald,
          title:          context.tr('profile.edit_profile'),
          semanticsLabel: context.tr('profile.edit_profile'),
          onTap:          () => context.push(AppRoutes.editProfile),
        ),
        SettingsTile(
          icon:           AppIcons.info,
          iconColor:      AppTheme.iconIndigo,
          title:          context.tr('profile.about'),
          semanticsLabel: context.tr('profile.about'),
          onTap:          () => context.push(AppRoutes.about),
        ),
        SettingsTile(
          icon:           AppIcons.help,
          iconColor:      AppTheme.iconPink,
          title:          context.tr('profile.help'),
          semanticsLabel: context.tr('profile.help'),
          onTap:          () => context.push(AppRoutes.help),
        ),

        const SizedBox(height: AppConstants.spacingSm),

        SignOutTile(
          onSignOut: isActionInProgress ? () {} : () => _confirmSignOut(context, ref),
          isEnabled: !isActionInProgress,
        ),

        const SizedBox(height: AppConstants.spacingXs),

        _DeleteAccountTile(
          isEnabled: !isActionInProgress,
          onTap:     () => _confirmDeleteAccount(context, ref),
        ),

        const SizedBox(height: AppConstants.spacingXl),

        Center(
          child: Text(
            '${context.tr('profile.version')} ${AppConstants.appVersion}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final languageService = ref.read(languageServiceProvider);
    final current         = languageService.currentLocale.languageCode;

    showModalBottomSheet<void>(
      context:            context,
      backgroundColor:    Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => GlassBottomSheet(
        title: context.tr('settings.language'),
        children: [
          SheetOption(
            label:      'Français',
            flag:       '🇫🇷',
            isSelected: current == 'fr',
            onTap: () {
              Navigator.of(sheetCtx).pop();
              languageService.changeToFrench();
            },
          ),
          SheetOption(
            label:      'English',
            flag:       '🇬🇧',
            isSelected: current == 'en',
            onTap: () {
              Navigator.of(sheetCtx).pop();
              languageService.changeToEnglish();
            },
          ),
          SheetOption(
            label:      'العربية',
            flag:       '🇩🇿',
            isSelected: current == 'ar',
            onTap: () {
              Navigator.of(sheetCtx).pop();
              languageService.changeToArabic();
            },
          ),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet<void>(
      context:            context,
      backgroundColor:    Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => GlassBottomSheet(
        title: context.tr('settings.theme'),
        children: [
          SheetOption(
            label:      context.tr('settings.system'),
            icon:       Icons.brightness_auto_rounded,
            isSelected: current == ThemeMode.system,
            onTap: () {
              Navigator.of(sheetCtx).pop();
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
            },
          ),
          SheetOption(
            label:      context.tr('settings.light'),
            icon:       Icons.light_mode_rounded,
            isSelected: current == ThemeMode.light,
            onTap: () {
              Navigator.of(sheetCtx).pop();
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
            },
          ),
          SheetOption(
            label:      context.tr('settings.dark'),
            icon:       Icons.dark_mode_rounded,
            isSelected: current == ThemeMode.dark,
            onTap: () {
              Navigator.of(sheetCtx).pop();
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
            },
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title:   Text(context.tr('auth.logout')),
        content: Text(context.tr('settings.logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child:     Text(context.tr('common.cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(settingsProvider.notifier).signOut();
            },
            child: Text(context.tr('auth.logout')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title:   Text(context.tr('settings.delete_account')),
        content: Text(context.tr('settings.delete_account_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child:     Text(context.tr('common.cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(settingsProvider.notifier).deleteAccount();
            },
            child: Text(context.tr('settings.delete_account_action')),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(BuildContext context, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => context.tr('settings.system'),
      ThemeMode.light  => context.tr('settings.light'),
      ThemeMode.dark   => context.tr('settings.dark'),
    };
  }
}

// ============================================================================
// PRIVATE — DELETE ACCOUNT TILE
// ============================================================================

class _DeleteAccountTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool         isEnabled;

  const _DeleteAccountTile({
    required this.onTap,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final isDark     = theme.brightness == Brightness.dark;
    final errorColor = isEnabled
        ? theme.colorScheme.error
        : theme.colorScheme.error.withOpacity(0.4);

    return Semantics(
      label:   context.tr('settings.delete_account'),
      button:  true,
      enabled: isEnabled,
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusTile),
        child: InkWell(
          onTap:        isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppConstants.radiusTile),
          child: Container(
            height: 64,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppConstants.paddingMd,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.error
                  .withOpacity(isEnabled ? (isDark ? 0.08 : 0.05) : 0.03),
              borderRadius: BorderRadius.circular(AppConstants.radiusTile),
              border: Border.all(
                color: theme.colorScheme.error
                    .withOpacity(isEnabled ? 0.15 : 0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width:  40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:        errorColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(AppIcons.deleteAccount, color: errorColor, size: 20),
                ),
                const SizedBox(width: AppConstants.spacingTileInner),
                Expanded(
                  child: Text(
                    context.tr('settings.delete_account'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize:   AppConstants.fontSizeTileLg,
                      fontWeight: FontWeight.w600,
                      color:      errorColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: errorColor.withOpacity(0.5),
                  size:  20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PRIVATE — PROFILE CARD SKELETON
// ============================================================================

class _ProfileCardSkeleton extends StatefulWidget {
  const _ProfileCardSkeleton();

  @override
  State<_ProfileCardSkeleton> createState() => _ProfileCardSkeletonState();
}

class _ProfileCardSkeletonState extends State<_ProfileCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ShimmerBox(
        height:       110,
        borderRadius: AppConstants.radiusCircle,
        opacity:      _anim.value,
      ),
    );
  }
}
