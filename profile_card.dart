// lib/screens/settings/widgets/profile_card.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/app_user_avatar.dart';
import '../settings_provider.dart';

// FIX (Structure): ProfileAvatar (profile_avatar.dart) merged here.
// The original file was 12 lines with zero added logic — a pure wrapper
// around AppUserAvatar used only by this widget. File deleted.

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
            color: Colors.white.withOpacity(0.20),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color:      accent.withOpacity(0.35),
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
            // Inlined from deleted profile_avatar.dart — zero logic change.
            AppUserAvatar(
              imageUrl:    state.profileImageUrl,
              name:        state.userName ?? '',
              radius:      32,
              borderColor: Colors.white.withOpacity(0.5),
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
                      // FIX: replaced raw Color(0xAA000000) with AppTheme token.
                      shadows: AppTheme.profileCardTextShadow,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (state.isWorkerAccount &&
                      state.professionLabel != null &&
                      state.professionLabel!.isNotEmpty) ...[ 
                    const SizedBox(height: AppConstants.spacingXs),
                    Container(
                      // FIX: replaced EdgeInsets.symmetric(horizontal: 10, vertical: 3)
                      // with AppConstants.badgePaddingH / badgePaddingV tokens.
                      // FIX: replaced BorderRadius.circular(20) with AppConstants.radiusXl.
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.badgePaddingH,
                        vertical:   AppConstants.badgePaddingV,
                      ),
                      decoration: BoxDecoration(
                        color:        Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
                      ),
                      child: Text(
                        context.tr('services.${state.professionLabel}'),
                        style: TextStyle(
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
                      style: TextStyle(
                        color:      Colors.white.withOpacity(0.9),
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
