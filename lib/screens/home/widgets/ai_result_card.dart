// lib/screens/home/widgets/ai_result_card.dart
// FIX (Structure): extracted from ai_search_sheet.dart where _ResultCard
// was an inline private class. Rule: one widget class = one file.

import 'package:flutter/material.dart';

import '../../../models/search_intent.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class AiResultCard extends StatelessWidget {
  final SearchIntent intent;
  final bool         isDark;

  const AiResultCard({
    super.key,
    required this.intent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final color  = AppTheme.getProfessionColor(
        intent.profession ?? '', isDark);
    final icon   = intent.profession != null
        ? AppTheme.getProfessionIcon(intent.profession!)
        : AppIcons.search;
    final pct    = (intent.confidence * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        decoration: BoxDecoration(
          color:        accent.withOpacity(isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
              color: accent.withOpacity(isDark ? 0.20 : 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('home.ai_result_label'),
              style: TextStyle(
                fontSize:      AppConstants.fontSizeXs,
                fontWeight:    FontWeight.w700,
                color:         accent,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Row(
              children: [
                Container(
                  width:  AppConstants.iconContainerLg,
                  height: AppConstants.iconContainerLg,
                  decoration: BoxDecoration(
                    color:  color.withOpacity(0.14),
                    shape:  BoxShape.circle,
                  ),
                  child: Center(
                      child: Icon(icon, size: 18, color: color)),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // FIX [CRITICAL]: was `'services.\${intent.profession}'`
                        // — the backslash escaped the $ preventing Dart string
                        // interpolation. The widget always rendered the literal
                        // key string instead of the translated service name.
                        intent.profession != null
                            ? context.tr('services.${intent.profession}')
                            : context.tr('home.filter_all'),
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color: isDark
                                  ? AppTheme.darkText
                                  : AppTheme.lightText,
                            ),
                      ),
                      if (intent.problemDescription != null &&
                          intent.problemDescription!.isNotEmpty)
                        Text(
                          intent.problemDescription!,
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeXs,
                            color: isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.spacingXs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                    vertical:   AppConstants.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color:        accent.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusXs),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize:   AppConstants.fontSizeXs,
                      fontWeight: FontWeight.w700,
                      color:      accent,
                    ),
                  ),
                ),
              ],
            ),
            if (intent.isUrgent) ...[
              const SizedBox(height: AppConstants.spacingXs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingSm,
                  vertical:   AppConstants.spacingXs,
                ),
                decoration: BoxDecoration(
                  color:        AppTheme.recordingRed.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusXs),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.warning,
                        size: 12, color: AppTheme.recordingRed),
                    const SizedBox(width: AppConstants.spacingXs),
                    Text(
                      context.tr('home.search_urgent_badge'),
                      style: TextStyle(
                        fontSize:   AppConstants.fontSizeXs,
                        fontWeight: FontWeight.w700,
                        color:      AppTheme.recordingRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
