// lib/screens/home/widgets/search_result_card.dart
//
// Unified result card for all three search modalities (AI text, image, voice).
// Replaces three near-identical private implementations:
//   • AiResultCard   (ai_result_card.dart)
//   • _ImageResultCard (image_search_sheet.dart)
//   • _VoiceResultPill (voice_search_sheet.dart)
//
// The [showTopLabel] flag switches between the two visual layouts:
//   • true  → "full" layout: "AI RESULT" badge above the row (AiResultCard style)
//   • false → "inline" layout: compact row only (Image/Voice style)

import 'package:flutter/material.dart';

import '../../../models/search_intent.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class SearchResultCard extends StatelessWidget {
  final SearchIntent intent;
  final bool         isDark;

  /// When true, renders the "AI RESULT" label above the main row and the
  /// problem description on a separate sub-line (used in AiSearchSheet).
  /// When false, renders a compact single-row layout (used in Image/Voice sheets).
  final bool showTopLabel;

  const SearchResultCard({
    super.key,
    required this.intent,
    required this.isDark,
    this.showTopLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final color  = accent;
    final icon   = intent.profession != null
        ? AppTheme.getProfessionIcon(intent.profession!)
        : AppIcons.search;
    final pct    = (intent.confidence * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color:        accent.withOpacity(isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border:       Border.all(
            color: accent.withOpacity(isDark ? 0.20 : 0.15)),
      ),
      child: showTopLabel
          ? _FullLayout(
              intent: intent,
              isDark: isDark,
              accent: accent,
              color:  color,
              icon:   icon,
              pct:    pct,
            )
          : _InlineLayout(
              intent: intent,
              isDark: isDark,
              accent: accent,
              color:  color,
              icon:   icon,
              pct:    pct,
            ),
    );
  }
}

// ── Full layout (AiResultCard) ────────────────────────────────────────────────

class _FullLayout extends StatelessWidget {
  final SearchIntent intent;
  final bool         isDark;
  final Color        accent;
  final Color        color;
  final IconData     icon;
  final int          pct;

  const _FullLayout({
    required this.intent,
    required this.isDark,
    required this.accent,
    required this.color,
    required this.icon,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "AI RESULT" label
        // [W6 FIX]: was TextStyle(fontSize: fontSizeXs, ...) — bypasses textTheme.
        // Replaced with textTheme.labelSmall?.copyWith(...).
        Text(
          context.tr('home.ai_result_label'),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight:    FontWeight.w700,
                color:         accent,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: AppConstants.spacingSm),

        // Icon + details + confidence
        Row(
          children: [
            _IconCircle(color: color, icon: icon),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intent.profession != null
                        ? context.tr('services.${intent.profession}')
                        : context.tr('home.filter_all'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                  ),
                  if (intent.problemDescription != null &&
                      intent.problemDescription!.isNotEmpty)
                    Text(
                      intent.problemDescription!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
            _ConfidenceBadge(pct: pct, accent: accent),
          ],
        ),

        // Urgent badge
        if (intent.isUrgent) ...[
          const SizedBox(height: AppConstants.spacingXs),
          const _UrgentBadge(),
        ],
      ],
    );
  }
}

// ── Inline layout (ImageResultCard / VoiceResultPill) ─────────────────────────

class _InlineLayout extends StatelessWidget {
  final SearchIntent intent;
  final bool         isDark;
  final Color        accent;
  final Color        color;
  final IconData     icon;
  final int          pct;

  const _InlineLayout({
    required this.intent,
    required this.isDark,
    required this.accent,
    required this.color,
    required this.icon,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconCircle(color: color, icon: icon),
        const SizedBox(width: AppConstants.spacingSm),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "AI RESULT" inline label
              // [W6 FIX]: was TextStyle(fontSize: fontSizeXs, ...) — bypasses textTheme.
              // Replaced with textTheme.labelSmall?.copyWith(...).
              Text(
                context.tr('home.ai_result_label'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight:    FontWeight.w700,
                      color:         accent,
                      letterSpacing: 0.5,
                    ),
              ),
              SizedBox(height: AppConstants.spacingXxs),

              Text(
                intent.profession != null
                    ? context.tr('services.${intent.profession}')
                    : context.tr('home.filter_all'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkText
                          : AppTheme.lightText,
                    ),
              ),

              if (intent.problemDescription != null &&
                  intent.problemDescription!.isNotEmpty)
                Text(
                  intent.problemDescription!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              if (intent.isUrgent)
                Padding(
                  padding: const EdgeInsets.only(top: AppConstants.spacingXs),
                  child: Text(
                    context.tr('home.search_urgent_badge'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:      AppTheme.recordingRed,
                        ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: AppConstants.spacingXs),
        _ConfidenceBadge(pct: pct, accent: accent),
      ],
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _IconCircle extends StatelessWidget {
  final Color    color;
  final IconData icon;
  const _IconCircle({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  AppConstants.iconContainerLg,
      height: AppConstants.iconContainerLg,
      decoration: BoxDecoration(
        color:  color.withOpacity(0.14),
        shape:  BoxShape.circle,
      ),
      child: Center(
        // [AUTO FIX W2]: was size: 18 — off-grid between iconSizeXs=16 and
        // iconSizeSm=20. Raised to AppConstants.iconSizeSm (20dp) — on-grid
        // and proportional to the 36dp iconContainerLg container.
        child: Icon(icon, size: AppConstants.iconSizeSm, color: color),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final int   pct;
  final Color accent;
  const _ConfidenceBadge({required this.pct, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical:   AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color:        accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusXs),
      ),
      child: Text(
        '$pct%',
        // [W6 FIX]: was TextStyle(fontSize: fontSizeXs, ...) — bypasses textTheme.
        // Replaced with textTheme.labelSmall?.copyWith(...).
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color:      accent,
            ),
      ),
    );
  }
}

class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical:   AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color:        AppTheme.recordingRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.warning, size: 12, color: AppTheme.recordingRed),
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            context.tr('home.search_urgent_badge'),
            // [W6 FIX]: was TextStyle(fontSize: fontSizeXs, ...) — bypasses textTheme.
            // Replaced with textTheme.labelSmall?.copyWith(...).
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:      AppTheme.recordingRed,
                ),
          ),
        ],
      ),
    );
  }
}
