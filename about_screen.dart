// lib/screens/about/about_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../widgets/app_section_header.dart';

// ============================================================================
// ABOUT SCREEN
// CHANGES:
//   • AppBar → SliverAppBar.medium  — عنوان يتحرك مع الشاشة (Material 3)
//   • extendBodyBehindAppBar removed — لم يعد ضرورياً مع SliverAppBar
//   • top-padding calculation removed — SliverAppBar يتولّاها تلقائياً
//   • radiusLg token (12) بدلاً من hardcoded 20 على حاوية الأيقونة (P3 fix)
//   • backgroundColor موحّد على darkBackground/lightBackground (P1 fix)
// ============================================================================

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static BoxDecoration _surface(bool isDark, {double radius = 16}) => BoxDecoration(
    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
      width: 0.5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final theme   = Theme.of(context);
    final accent  = theme.colorScheme.primary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle(
        statusBarColor:                    Colors.transparent,
        statusBarIconBrightness:           isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:               isDark ? Brightness.dark  : Brightness.light,
        systemNavigationBarColor:          Colors.transparent,
        systemNavigationBarDividerColor:   Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      )
          : SystemUiOverlayStyle(
        statusBarColor:                    Colors.transparent,
        statusBarIconBrightness:           isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:               isDark ? Brightness.dark  : Brightness.light,
        systemNavigationBarColor:          Colors.transparent,
        systemNavigationBarDividerColor:   Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
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
                context.tr('profile.about'),
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

            // ── Content ──────────────────────────────────────────────────────
            SliverPadding(
              padding: EdgeInsetsDirectional.only(
                top:    AppConstants.spacingMd,
                bottom: MediaQuery.of(context).padding.bottom + AppConstants.spacingXl,
                start:  AppConstants.paddingMd,
                end:    AppConstants.paddingMd,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── App identity ───────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width:  80,
                          height: 80,
                          decoration: BoxDecoration(
                            // FIX (P3): was hardcoded 20 — now uses AppConstants token
                            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                            color: accent,
                            boxShadow: [
                              BoxShadow(
                                color:      accent.withOpacity(0.40),
                                blurRadius: 20,
                                offset:     const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.home_repair_service_rounded,
                            size:  40,
                            color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        Text(
                          context.tr('common.app_name'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${context.tr('profile.version')} ${AppConstants.appVersion}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXl),

                  // ── Description ────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMd),
                    decoration: _surface(isDark),
                    child: Text(
                      context.tr('about.description'),
                      style:     theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // ── Legal ──────────────────────────────────────────────────
                  AppSectionHeader(label: context.tr('about.legal')),
                  const SizedBox(height: AppConstants.spacingSm),

                  _LinkTile(
                    isDark:    isDark,
                    icon:      Icons.privacy_tip_outlined,
                    iconColor: AppTheme.iconIndigo,
                    label:     context.tr('about.privacy_policy'),
                    url:       'https://khidmeti.app/privacy',
                  ),
                  _LinkTile(
                    isDark:    isDark,
                    icon:      Icons.gavel_rounded,
                    iconColor: AppTheme.iconIndigo,
                    label:     context.tr('about.terms'),
                    url:       'https://khidmeti.app/terms',
                  ),
                  _LinkTile(
                    isDark:    isDark,
                    icon:      Icons.code_rounded,
                    iconColor: AppTheme.iconViolet,
                    label:     context.tr('about.open_source'),
                    url:       'https://khidmeti.app/licenses',
                  ),
                  const SizedBox(height: AppConstants.spacingMdLg),

                  // ── Contact ────────────────────────────────────────────────
                  AppSectionHeader(label: context.tr('about.contact')),
                  const SizedBox(height: AppConstants.spacingSm),

                  _LinkTile(
                    isDark:    isDark,
                    icon:      AppIcons.email,
                    iconColor: AppTheme.iconEmerald,
                    label:     context.tr('about.contact_email'),
                    url:       'mailto:support@khidmeti.app',
                  ),
                  const SizedBox(height: AppConstants.spacingXl),

                  // ── Footer ─────────────────────────────────────────────────
                  Center(
                    child: Text(
                      context.tr('about.copyright'),
                      style:     theme.textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
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
// PRIVATE — LINK TILE (unchanged)
// ============================================================================

class _LinkTile extends StatelessWidget {
  final bool     isDark;
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   url;

  const _LinkTile({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.url,
  });

  Future<void> _launch() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label:  label,
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusTile),
          child: InkWell(
            onTap:        _launch,
            borderRadius: BorderRadius.circular(AppConstants.radiusTile),
            child: Container(
              height: 64,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppConstants.paddingMd,
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
                    child: Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize:   AppConstants.fontSizeTileLg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded, size: 18, color: theme.colorScheme.outline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
