// lib/screens/service_request/widgets/service_type_card.dart
//
// [C1] FIX: fontSize: AppConstants.fontSizeXs (10dp) → fontSizeXxs (11dp)
//      on availability label.
// [W6] FIX: check badge icon size: 10dp → 12dp (legibility).

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

// ============================================================================
// SERVICE TYPE CARD
// 2-column grid card: coloured header band + icon + name + availability dot.
// ============================================================================

class ServiceTypeCard extends StatelessWidget {
  final String type;
  final String label;
  final String availabilityLabel;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const ServiceTypeCard({
    super.key,
    required this.type,
    required this.label,
    required this.availabilityLabel,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getProfessionColor(type, isDark);

    return Semantics(
      button: true,
      label: label,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.6)
                  : (isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.07)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            child: Column(
              children: [
                // ── Coloured header band ──────────────────────────────
                Container(
                  height: 68,
                  color: isSelected
                      ? color.withOpacity(0.14)
                      : color.withOpacity(0.08),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(icon, size: 28, color: color),
                      // Checkmark badge
                      if (isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 17,
                            height: 17,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            // [W6] FIX: check badge icon size 10dp → 12dp
                            child: const Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Text body ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? color
                                  : (isDark
                                      ? AppTheme.darkText
                                      : AppTheme.lightText),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSuccess
                                  : AppTheme.lightSuccess,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingXs),
                          Expanded(
                            child: Text(
                              availabilityLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    // [C1] FIX: fontSizeXs (10dp) → fontSizeXxs (11dp)
                                    fontSize: AppConstants.fontSizeXxs,
                                    color: isDark
                                        ? AppTheme.darkSuccess
                                        : AppTheme.lightSuccess,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
