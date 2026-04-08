// lib/screens/service_request/widgets/rating_summary.dart
//
// [W6] FIX: star icon size: 14dp (off-grid, no token) →
//      AppConstants.iconSizeXs (16dp — nearest on-grid token above 14dp).
//      16dp is the smallest named icon token in the system.

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// RATING SUMMARY
// Confirmation banner showing submitted star rating.
// ============================================================================

class RatingSummary extends StatelessWidget {
  final int  rating;
  final bool isDark;

  const RatingSummary({
    super.key,
    required this.rating,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color:        AppTheme.acceptGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border:       Border.all(color: AppTheme.acceptGreen.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.check, size: 18, color: AppTheme.acceptGreen),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Text(
              context.tr('tracking.already_rated'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:      AppTheme.acceptGreen,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < rating ? AppIcons.ratingFilled : AppIcons.ratingOutlined,
                // [W6] FIX: size: 14 (off-grid) → iconSizeXs (16dp)
                size:  AppConstants.iconSizeXs,
                color: AppTheme.warningAmber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
