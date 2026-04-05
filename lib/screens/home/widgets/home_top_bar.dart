// lib/screens/home/widgets/home_top_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/home_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/wordmark.dart';
import 'location_address_display.dart';

class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAddress = ref.watch(
      homeControllerProvider.select((s) => s.userAddress),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final text   = isDark ? AppTheme.darkText   : AppTheme.lightText;

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top:    AppConstants.heroPaddingTop,
        start:  AppConstants.heroPaddingH,
        end:    AppConstants.heroPaddingH,
        bottom: AppConstants.heroPaddingBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Wordmark row ───────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppWordmark(isDark: isDark),
              const Spacer(),
              Semantics(
                label:  context.tr('profile.notifications'),
                button: true,
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.notifications),
                  child: GlassIconButton(
                    icon:   AppIcons.notifications,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // ── Hero question ──────────────────────────────────────────────────
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize:      AppConstants.heroFontSize,
                fontWeight:    FontWeight.w700,
                letterSpacing: -1.2,
                height:        1.02,
                color:         text,
              ),
              children: [
                TextSpan(text: context.tr('home.question_line1')),
                const TextSpan(text: '\n'),
                TextSpan(text: context.tr('home.question_line2')),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: context.tr('home.question_line3'),
                  style: TextStyle(
                    color: accent,
                    shadows: [
                      Shadow(
                        color:      accent.withOpacity(0.40),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fade(duration: 1000.ms, curve: Curves.easeOut)
              .slideY(begin: 0.3, end: 0, duration: 1000.ms, curve: Curves.easeOut)
              .shimmer(
                delay:    1500.ms,
                duration: 1500.ms,
                color:    accent.withOpacity(0.4),
              ),

          const SizedBox(height: AppConstants.spacingXs),

          // ── Subtitle ──────────────────────────────────────────────────────
          Text(
            context.tr('home.hero_subtitle'),
            style: TextStyle(
              // [UI-FIX TYPE]: was bare fontSize: 13 — untokenised.
              // Replaced with AppConstants.fontSizeCaption (13dp named token).
              fontSize: AppConstants.fontSizeCaption,
              color:    text.withOpacity(0.32),
              height:   1.5,
            ),
          )
              .animate()
              .fade(delay: 400.ms, duration: 800.ms)
              .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 800.ms),

          const SizedBox(height: AppConstants.spacingSm),

          // ── Location row ──────────────────────────────────────────────────
          LocationAddressDisplay(address: userAddress)
              .animate()
              .fade(delay: 700.ms, duration: 800.ms)
              .slideY(begin: 0.2, end: 0, delay: 700.ms, duration: 800.ms),
        ],
      ),
    );
  }
}
