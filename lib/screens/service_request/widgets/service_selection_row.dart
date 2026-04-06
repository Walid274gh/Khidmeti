// lib/screens/service_request/widgets/service_selection_row.dart
//
// CHANGE: _ServiceItem private class removed — replaced with public ServiceItem
//         imported from lib/models/service_item_model.dart.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/service_item_model.dart'; // NEW
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'service_selection_sheet.dart';

const double _kCardW   = 72.0;
const double _kCardH   = 80.0;
const double _kCircleD = 48.0;

class ServiceSelectionRow extends StatelessWidget {
  final String? selected;
  final bool isDark;
  final Color accentColor;
  final ValueChanged<String> onServiceSelected;

  const ServiceSelectionRow({
    super.key,
    required this.selected,
    required this.isDark,
    required this.accentColor,
    required this.onServiceSelected,
  });

  List<ServiceItem> _items(BuildContext context) => [
        ServiceItem(ServiceType.plumbing,
            context.tr('services.${ServiceType.plumbing}'), AppIcons.plumbing),
        ServiceItem(ServiceType.electrical,
            context.tr('services.${ServiceType.electrical}'), AppIcons.electrical),
        ServiceItem(ServiceType.cleaning,
            context.tr('services.${ServiceType.cleaning}'), AppIcons.cleaning),
        ServiceItem(ServiceType.painting,
            context.tr('services.${ServiceType.painting}'), AppIcons.painting),
        ServiceItem(ServiceType.carpentry,
            context.tr('services.${ServiceType.carpentry}'), AppIcons.carpentry),
        ServiceItem(ServiceType.airConditioning,
            context.tr('services.${ServiceType.airConditioning}'), AppIcons.airConditioning),
        ServiceItem(ServiceType.gardening,
            context.tr('services.${ServiceType.gardening}'), AppIcons.gardening),
      ];

  @override
  Widget build(BuildContext context) {
    final items = _items(context);

    return SizedBox(
      height: _kCardH,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _ServiceChip(
                item:     item,
                isActive: selected == item.type,
                isDark:   isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onServiceSelected(item.type);
                },
              ),
            ),
          ),

          _AllServicesChip(
            isDark:              isDark,
            accentColor:         accentColor,
            selected:            selected,
            onServiceSelected:   onServiceSelected,
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final ServiceItem item; // WAS: _ServiceItem (private)
  final bool        isActive;
  final bool        isDark;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

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
                      ? Border.all(color: color.withOpacity(0.45), width: 1.5)
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

              const SizedBox(height: 7),

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

class _AllServicesChip extends StatelessWidget {
  final bool                 isDark;
  final Color                accentColor;
  final String?              selected;
  final ValueChanged<String> onServiceSelected;

  const _AllServicesChip({
    required this.isDark,
    required this.accentColor,
    required this.selected,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  context.tr('home.see_all'),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ServiceSelectionSheet.show(
            context,
            selected:          selected,
            onServiceSelected: onServiceSelected,
          );
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
                  color: accentColor.withOpacity(isDark ? 0.12 : 0.08),
                  border: Border.all(
                    color: accentColor.withOpacity(0.30),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(AppIcons.gridView, color: accentColor, size: 20),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                context.tr('home.see_all'),
                style: TextStyle(
                  fontSize:   AppConstants.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  color:      accentColor,
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
