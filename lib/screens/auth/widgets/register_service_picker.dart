// lib/screens/auth/widgets/register_service_picker.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// SERVICE PICKER DATA
// ============================================================================

const List<Map<String, dynamic>> kRegisterServices = [
  {'key': 'plumber',     'icon': Icons.water_drop_outlined},
  {'key': 'electrician', 'icon': Icons.bolt_outlined},
  {'key': 'carpenter',   'icon': Icons.handyman_outlined},
  {'key': 'painter',     'icon': Icons.format_paint_outlined},
  {'key': 'cleaner',     'icon': Icons.cleaning_services_outlined},
  {'key': 'gardener',    'icon': Icons.park_outlined},
  {'key': 'mechanic',    'icon': Icons.build_outlined},
  {'key': 'mover',       'icon': Icons.local_shipping_outlined},
];

// ============================================================================
// SERVICE PICKER — solid Rose selected tile, no gradient
// ============================================================================

class RegisterServicePicker extends StatelessWidget {
  final String?              selected;
  final bool                 isDark;
  final bool                 enabled;
  final ValueChanged<String> onSelected;

  const RegisterServicePicker({
    super.key,
    required this.selected,
    required this.isDark,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
          child: Text(
            context.tr('register.service_label'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize:   AppConstants.fontSizeCaption,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics:    const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   4,
            crossAxisSpacing: AppConstants.spacingSm,
            mainAxisSpacing:  AppConstants.spacingSm,
            childAspectRatio: 0.9,
          ),
          itemCount: kRegisterServices.length,
          itemBuilder: (context, i) {
            final svc        = kRegisterServices[i];
            final key        = svc['key'] as String;
            final icon       = svc['icon'] as IconData;
            final isSelected = selected == key;
            final accent     = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
            final bgColor    = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

            return Semantics(
              button:   true,
              selected: isSelected,
              label:    context.tr('services.$key'),
              child: GestureDetector(
                onTap: enabled ? () => onSelected(key) : null,
                child: AnimatedContainer(
                  duration: AppConstants.animDurationMicro,
                  decoration: BoxDecoration(
                    // FIX [Col2]: replaced 4× inline .withOpacity() calls with
                    // pre-baked AppTheme tokens:
                    //   Colors.white.withOpacity(0.06) → AppTheme.darkTileFill
                    //   Colors.black.withOpacity(0.04) → AppTheme.lightTileFill
                    //   Colors.white.withOpacity(0.10) → AppTheme.darkTileBorder
                    //   Colors.black.withOpacity(0.08) → AppTheme.lightTileBorder
                    color: isSelected
                        ? accent
                        : (isDark
                            ? AppTheme.darkTileFill
                            : AppTheme.lightTileFill),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? accent
                          : (isDark
                              ? AppTheme.darkTileBorder
                              : AppTheme.lightTileBorder),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size:  22,
                        color: isSelected
                            ? bgColor
                            : (isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText),
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        context.tr('services.$key'),
                        style: TextStyle(
                          fontSize:   AppConstants.fontSizeXs,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? bgColor
                              : (isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText),
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
          },
        ),
      ],
    );
  }
}
