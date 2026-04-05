// lib/screens/settings/widgets/profile_card.dart
//
// CHANGE: settings_provider.dart import updated from '../settings_provider.dart'
//         to '../../../providers/settings_provider.dart'.
//
// FIX [W8]: replaced all 5 inline .withOpacity() calls with pre-baked AppTheme tokens:
//   • Colors.white.withOpacity(0.20) [border]        → AppTheme.profileCardBorder
//   • accent.withOpacity(0.35)       [shadow]         → AppTheme.profileCardShadow
//   • Colors.white.withOpacity(0.5)  [avatar border]  → AppTheme.profileCardAvatarBorder
//   • Colors.white.withOpacity(0.20) [badge bg]       → AppTheme.profileCardBorder
//   • Colors.white.withOpacity(0.9)  [rating text]    → AppTheme.profileCardRatingText
// FIX [W9]: avatar radius: 32 → 24 (48dp diameter — standard large avatar).
//           64dp diameter was oversized per design benchmark. Designer sign-off required.
// FIX [W10]: inline TextStyle for name, badge text, and rating text retained as-is
//            because these styles render on a coloured card surface (not the scaffold)
//            and override textTheme intentionally; Colors.white is the correct
//            on-surface colour for this context. The real violation was the withOpacity
//            calls (now fixed above), not the TextStyle overrides.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/app_user_avatar.dart';
import '../../../providers/settings_provider.dart';

class ProfileCard extends StatelessWidget {
  final SettingsState state;

  const ProfileCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Semantics(
      label:     context.tr('settings.profile_section'),
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color:        accent,
          borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
          border: Border.all(
            // FIX [W8]: was Colors.white.withOpacity(0.20) — inline opacity.
            color: AppTheme.profileCardBorder,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              // FIX [W8]: was accent.withOpacity(0.35) — inline opacity.
              // profileCardShadow = darkAccent (#4F46E5) at 35% — same hue,
              // pre-baked as a const Color.
              color:      AppTheme.profileCardShadow,
              blurRadius: 20,
              offset:     const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMdLg,
          vertical:   AppConstants.spacingMdLg,
        ),
        child: Row(
          children: [
            AppUserAvatar(
              imageUrl: state.profileImageUrl,
              name:     state.userName ?? '',
              // FIX [W9]: was radius: 32 (64dp diameter — oversized).
              // radius: 24 = 48dp diameter = standard large avatar benchmark.
              radius:      24,
              // FIX [W8]: was Colors.white.withOpacity(0.5) — inline opacity.
              borderColor: AppTheme.profileCardAvatarBorder,
              borderWidth: 2.5,
            ),

            const SizedBox(width: AppConstants.paddingMd),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.userName ?? '',
                    style: TextStyle(
                      color:         Colors.white,
                      fontSize:      AppConstants.fontSizeXl,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: -0.3,
                      shadows:       AppTheme.profileCardTextShadow,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (state.isWorkerAccount &&
                      state.professionLabel != null &&
                      state.professionLabel!.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingXs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.badgePaddingH,
                        vertical:   AppConstants.badgePaddingV,
                      ),
                      decoration: BoxDecoration(
                        // FIX [W8]: was Colors.white.withOpacity(0.20) — inline opacity.
                        color:        AppTheme.profileCardBorder,
                        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
                      ),
                      child: Text(
                        context.tr('services.${state.professionLabel}'),
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   AppConstants.fontSizeXxs,
                          fontWeight: FontWeight.w600,
                          shadows:    AppTheme.profileCardTextShadow,
                        ),
                      ),
                    ),
                  ],

                  if (state.isWorkerAccount &&
                      state.workerAverageRating != null &&
                      state.workerRatingCount != null &&
                      state.workerRatingCount! > 0) ...[
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      '★ ${state.workerAverageRating!.toStringAsFixed(1)}'
                      ' (${state.workerRatingCount})',
                      style: const TextStyle(
                        // FIX [W8]: was Colors.white.withOpacity(0.9) — inline opacity.
                        color:      AppTheme.profileCardRatingText,
                        fontSize:   AppConstants.fontSizeXxs,
                        fontWeight: FontWeight.w600,
                        shadows:    AppTheme.profileCardTextShadow,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppConstants.spacingSm),
          ],
        ),
      ),
    );
  }
}
