// lib/screens/help/help_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../widgets/app_section_header.dart';

// ============================================================================
// HELP SCREEN
// CHANGES:
//   • AppBar → SliverAppBar.medium  — عنوان يتحرك مع الشاشة
//   • extendBodyBehindAppBar + top padding calculation removed
//   • backgroundColor موحّد على darkBackground/lightBackground (P1 fix)
// ============================================================================

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
                context.tr('profile.help'),
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

                  // ── FAQ ────────────────────────────────────────────────────
                  AppSectionHeader(label: context.tr('help.faq')),
                  const SizedBox(height: AppConstants.spacingSm),

                  _FaqItem(isDark: isDark, question: context.tr('help.faq_q1'), answer: context.tr('help.faq_a1')),
                  _FaqItem(isDark: isDark, question: context.tr('help.faq_q2'), answer: context.tr('help.faq_a2')),
                  _FaqItem(isDark: isDark, question: context.tr('help.faq_q3'), answer: context.tr('help.faq_a3')),
                  _FaqItem(isDark: isDark, question: context.tr('help.faq_q4'), answer: context.tr('help.faq_a4')),
                  _FaqItem(isDark: isDark, question: context.tr('help.faq_q5'), answer: context.tr('help.faq_a5')),
                  const SizedBox(height: AppConstants.spacingXl),

                  // ── Contact ────────────────────────────────────────────────
                  AppSectionHeader(label: context.tr('help.contact')),
                  const SizedBox(height: AppConstants.spacingSm),

                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingMdLg),
                    decoration: _surface(isDark, radius: AppConstants.radiusLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('help.contact_body'), style: theme.textTheme.bodyMedium),
                        const SizedBox(height: AppConstants.spacingMd),
                        Semantics(
                          label:  context.tr('help.send_email'),
                          button: true,
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon:  const Icon(AppIcons.email),
                              label: Text(context.tr('help.send_email')),
                              onPressed: () async {
                                final uri = Uri.parse(
                                  'mailto:support@khidmeti.app?subject=Support%20Request',
                                );
                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                              },
                            ),
                          ),
                        ),
                      ],
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
// PRIVATE — FAQ ITEM (unchanged)
// ============================================================================

class _FaqItem extends StatelessWidget {
  final bool   isDark;
  final String question;
  final String answer;

  const _FaqItem({
    required this.isDark,
    required this.question,
    required this.answer,
  });

  static BoxDecoration _surface(bool isDark) => BoxDecoration(
    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
    borderRadius: BorderRadius.circular(AppConstants.radiusTile),
    border: Border.all(
      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
      width: 0.5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusTile),
        child: Container(
          decoration: _surface(isDark),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              backgroundColor:          Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              tilePadding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppConstants.paddingMd,
              ),
              childrenPadding: const EdgeInsetsDirectional.only(
                start:  AppConstants.paddingMd,
                end:    AppConstants.paddingMd,
                bottom: AppConstants.paddingMd,
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              leading: Container(
                width:  40,
                height: 40,
                decoration: BoxDecoration(
                  color:        theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: theme.colorScheme.primary,
                  size:  20,
                ),
              ),
              title: Text(
                question,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize:   AppConstants.fontSizeTileLg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Text(
                  answer,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:  theme.colorScheme.onSurface.withOpacity(0.75),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
