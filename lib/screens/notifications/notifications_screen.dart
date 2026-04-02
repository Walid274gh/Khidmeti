// lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/app_section_header.dart';
import '../../providers/notification_prefs_controller.dart';

// ============================================================================
// NOTIFICATIONS SCREEN
// CHANGES:
//   • AppBar → SliverAppBar.medium — عنوان يتحرك مع الشاشة
//   • Loading state → SliverFillRemaining — AppBar يبقى ظاهراً أثناء التحميل
//   • backgroundColor موحّد على darkBackground/lightBackground (P1 fix)
//   • extendBodyBehindAppBar + top padding calculation removed
// ============================================================================

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final theme    = Theme.of(context);
    final bgColor  = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          slivers: [
            // ── Scrolling app bar ────────────────────────────────────────────
            SliverAppBar.medium(
              backgroundColor:        bgColor,
              surfaceTintColor:       Colors.transparent,
              scrolledUnderElevation: 0,
              title: Text(
                context.tr('notifications.title'),
                style: theme.textTheme.titleLarge,
              ),
              centerTitle: false,
              leading: Semantics(
                label: context.tr('common.back'),
                child: IconButton(
                  icon:     const Icon(AppIcons.back),
                  onPressed: () => context.pop(),
                  tooltip:  context.tr('common.back'),
                ),
              ),
            ),

            // ── Loading — AppBar stays visible while spinner shows in body ───
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )

            // ── Content ──────────────────────────────────────────────────────
            else
              SliverPadding(
                padding: EdgeInsetsDirectional.only(
                  top:    AppConstants.spacingMd,
                  bottom: MediaQuery.of(context).padding.bottom + AppConstants.spacingLg,
                  start:  AppConstants.paddingMd,
                  end:    AppConstants.paddingMd,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    if (state.systemPermissionDenied) ...[
                      _PermissionWarningBanner(),
                      const SizedBox(height: AppConstants.spacingMd),
                    ],

                    AppSectionHeader(label: context.tr('notifications.activity')),
                    const SizedBox(height: AppConstants.spacingSm),

                    _NotifToggleTile(
                      isDark:    isDark,
                      icon:      AppIcons.requests,
                      // FIX (P3): was darkAccent — icons should use semantic icon tokens,
                      // not the CTA accent. Using iconIndigo for consistency with other screens.
                      iconColor: AppTheme.iconIndigo,
                      title:     context.tr('notifications.new_requests'),
                      subtitle:  context.tr('notifications.new_requests_sub'),
                      value:     state.newRequests,
                      onChanged: (v) => notifier.setNewRequests(v),
                    ),
                    _NotifToggleTile(
                      isDark:    isDark,
                      icon:      AppIcons.jobs,
                      iconColor: AppTheme.iconEmerald,
                      title:     context.tr('notifications.bid_received'),
                      subtitle:  context.tr('notifications.bid_received_sub'),
                      value:     state.bidReceived,
                      onChanged: (v) => notifier.setBidReceived(v),
                    ),
                    _NotifToggleTile(
                      isDark:    isDark,
                      icon:      AppIcons.messages,
                      iconColor: AppTheme.iconIndigo,
                      title:     context.tr('notifications.chat_messages'),
                      subtitle:  context.tr('notifications.chat_messages_sub'),
                      value:     state.chatMessages,
                      onChanged: (v) => notifier.setChatMessages(v),
                    ),

                    const SizedBox(height: AppConstants.spacingMdLg),
                    AppSectionHeader(label: context.tr('notifications.marketing')),
                    const SizedBox(height: AppConstants.spacingSm),

                    _NotifToggleTile(
                      isDark:    isDark,
                      icon:      AppIcons.notifications,
                      iconColor: AppTheme.iconViolet,
                      title:     context.tr('notifications.promotions'),
                      subtitle:  context.tr('notifications.promotions_sub'),
                      value:     state.promotions,
                      onChanged: (v) => notifier.setPromotions(v),
                    ),

                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PRIVATE — PERMISSION WARNING BANNER (unchanged)
// ============================================================================

class _PermissionWarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color:        theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusTile),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_off_outlined, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('notifications.system_disabled'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('notifications.open_settings_hint'))),
              );
            },
            child: Text(
              context.tr('common.settings'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PRIVATE — NOTIFICATION TOGGLE TILE (unchanged)
// ============================================================================

class _NotifToggleTile extends StatelessWidget {
  final bool               isDark;
  final IconData           icon;
  final Color              iconColor;
  final String             title;
  final String             subtitle;
  final bool               value;
  final ValueChanged<bool> onChanged;

  const _NotifToggleTile({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label:   title,
      toggled: value,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusTile),
          child: InkWell(
            onTap:        () => onChanged(!value),
            borderRadius: BorderRadius.circular(AppConstants.radiusTile),
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppConstants.paddingMd,
                vertical:   14,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(AppConstants.radiusTile),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width:  40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:        iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize:   AppConstants.fontSizeTileLg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(value: value, onChanged: onChanged),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
