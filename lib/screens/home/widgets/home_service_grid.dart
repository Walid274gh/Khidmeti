// lib/screens/home/widgets/home_service_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'home_categories_sheet.dart';
import 'worker_story_modal.dart';

// ─── Dimensions ───────────────────────────────────────────────────────────────
const double _kCardW    = 72.0;
const double _kCardH    = 80.0;
const double _kCircleD  = 48.0;

class HomeServiceGrid extends StatelessWidget {
  final String?               activeFilter;
  final ValueChanged<String?> onFilterChanged;

  final bool isWorker;
  final bool workerIsOnline;

  const HomeServiceGrid({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    this.isWorker      = false,
    this.workerIsOnline = false,
  });

  List<_ServiceItem> _items(BuildContext context) => [
    _ServiceItem(ServiceType.plumbing,
        context.tr('services.plumber'),     AppIcons.plumbing),
    _ServiceItem(ServiceType.electrical,
        context.tr('services.electrician'), AppIcons.electrical),
    _ServiceItem(ServiceType.cleaning,
        context.tr('services.cleaner'),     AppIcons.cleaning),
    _ServiceItem(ServiceType.painting,
        context.tr('services.painter'),     AppIcons.painting),
    _ServiceItem(ServiceType.carpentry,
        context.tr('services.carpenter'),   AppIcons.carpentry),
    _ServiceItem(ServiceType.airConditioning,
        context.tr('services.ac_repair'),   AppIcons.airConditioning),
    _ServiceItem(ServiceType.gardening,
        context.tr('services.gardener'),    AppIcons.gardening),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items  = _items(context);

    return SizedBox(
      height: _kCardH,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics:         const BouncingScrollPhysics(),
        children: [
          if (isWorker) ...[
            _VousChip(
              isDark:   isDark,
              isOnline: workerIsOnline,
            ),
            // [UI-FIX SPACING]: was SizedBox(width: 12) — untokenised 12dp.
            // Replaced with AppConstants.spacingChipGap (12dp named token).
            const SizedBox(width: AppConstants.spacingChipGap),
          ],

          ...items.map((item) => Padding(
            // [UI-FIX SPACING]: was EdgeInsets.only(right: 12) — same fix.
            padding: const EdgeInsets.only(right: AppConstants.spacingChipGap),
            child: _ServiceChip(
              item:     item,
              isActive: activeFilter == item.type,
              isDark:   isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                onFilterChanged(item.type);
              },
            ),
          )),

          _AllServicesChip(
            isDark:          isDark,
            onFilterChanged: onFilterChanged,
          ),
        ],
      ),
    );
  }
}

// ── "Vous" chip ────────────────────────────────────────────────────────────────

class _VousChip extends StatelessWidget {
  final bool isDark;
  final bool isOnline;

  const _VousChip({
    required this.isDark,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline
        ? AppTheme.onlineGreen
        : AppTheme.recordingRed;

    return Semantics(
      button: true,
      label:  context.tr('worker_home.chip_vous'),
      child: GestureDetector(
        onTap: () => WorkerStoryModal.show(context),
        child: SizedBox(
          width: _kCardW,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve:    Curves.easeOutCubic,
                width:    _kCircleD,
                height:   _kCircleD,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withOpacity(isDark ? 0.12 : 0.09),
                  border: Border.all(
                    color: statusColor.withOpacity(0.45),
                    width: 1.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    AppIcons.profile,
                    color: statusColor.withOpacity(isDark ? 0.85 : 0.80),
                    size:  20,
                  ),
                ),
              ),
              SizedBox(height: AppConstants.cardIconLabelGap),
              Text(
                context.tr('worker_home.chip_vous'),
                style: TextStyle(
                  fontSize:   AppConstants.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  color:      statusColor,
                  height:     1.2,
                ),
                textAlign: TextAlign.center,
                maxLines:  1,
                overflow:  TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Service chip ───────────────────────────────────────────────────────────────

class _ServiceChip extends StatelessWidget {
  final _ServiceItem item;
  final bool         isActive;
  final bool         isDark;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getProfessionColor(item.type, isDark);

    return Semantics(
      button:   true,
      label:    item.label,
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: _kCardW,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve:    Curves.easeOutCubic,
                width:    _kCircleD,
                height:   _kCircleD,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? color.withOpacity(isDark ? 0.24 : 0.15)
                      : color.withOpacity(isDark ? 0.12 : 0.09),
                  border: isActive
                      ? Border.all(
                          color: color.withOpacity(0.45),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    color: isActive
                        ? color
                        : color.withOpacity(isDark ? 0.75 : 0.65),
                    size: 20,
                  ),
                ),
              ),
              SizedBox(height: AppConstants.cardIconLabelGap),
              Text(
                item.label,
                style: TextStyle(
                  fontSize:   AppConstants.fontSizeXs,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? color
                      : (isDark
                          ? AppTheme.darkText
                          : AppTheme.lightSecondaryText),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines:  2,
                overflow:  TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── "Tout voir" chip ──────────────────────────────────────────────────────────

class _AllServicesChip extends StatelessWidget {
  final bool                  isDark;
  final ValueChanged<String?> onFilterChanged;

  const _AllServicesChip({
    required this.isDark,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Semantics(
      button: true,
      label:  context.tr('home.see_all'),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          HomeCategoriesSheet.show(context, onFilterChanged);
        },
        child: SizedBox(
          width: _kCardW,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width:  _kCircleD,
                height: _kCircleD,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:  accent.withOpacity(isDark ? 0.12 : 0.08),
                  border: Border.all(
                    color: accent.withOpacity(0.30),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    AppIcons.gridView,
                    color: accent,
                    size:  20,
                  ),
                ),
              ),
              SizedBox(height: AppConstants.cardIconLabelGap),
              Text(
                context.tr('home.see_all'),
                style: TextStyle(
                  fontSize:   AppConstants.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  color:      accent,
                  height:     1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _ServiceItem {
  final String   type;
  final String   label;
  final IconData icon;
  const _ServiceItem(this.type, this.label, this.icon);
}
