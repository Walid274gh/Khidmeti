// lib/screens/auth/widgets/register_role_selector.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';


class RegisterRoleSelector extends StatelessWidget {
  final bool               isWorker;
  final bool               isDark;
  final ValueChanged<bool> onChanged;

  const RegisterRoleSelector({
    super.key,
    required this.isWorker,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final valueKey = isWorker
        ? 'register.role_value_worker'
        : 'register.role_value_client';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Toggle ────────────────────────────────────────────────────────────
        Container(
          // FIX [Dim-RAW]: was height: 56 (magic literal) — replaced with
          // AppConstants.roleToggleHeight (56.0). Distinct from buttonHeight
          // (54dp); separate token prevents silent divergence.
          height: AppConstants.roleToggleHeight,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              _RoleTab(
                label: context.tr('register.role_client'),
                icon:  AppIcons.profile,
                isSelected: !isWorker,
                isDark: isDark,
                onTap:  () => onChanged(false),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppConstants.radiusMd),
                ),
              ),
              _RoleTab(
                label: context.tr('register.role_worker'),
                icon:  AppIcons.jobs,
                isSelected: isWorker,
                isDark: isDark,
                onTap:  () => onChanged(true),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(AppConstants.radiusMd),
                ),
              ),
            ],
          ),
        ),

        // ── Value proposition line — changes with selection ───────────────────
        AnimatedSwitcher(
          duration: AppConstants.animDurationMicro,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Padding(
            key: ValueKey<String>(valueKey),
            padding: const EdgeInsets.only(
              top: AppConstants.spacingXs,
              left: AppConstants.paddingXs,
            ),
            child: Text(
              context.tr(valueKey),
              style: TextStyle(
                fontSize: AppConstants.fontSizeSm,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ROLE TAB  (helper)
// ============================================================================

class _RoleTab extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         isSelected;
  final bool         isDark;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _RoleTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final accent  = isDark ? AppTheme.darkAccent    : AppTheme.lightAccent;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Expanded(
      child: Semantics(
        button:   true,
        selected: isSelected,
        label:    label,
        child: AnimatedContainer(
          duration: AppConstants.animDurationMicro,
          curve:    Curves.easeOut,
          decoration: BoxDecoration(
            color:        isSelected ? accent : Colors.transparent,
            borderRadius: borderRadius,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:        onTap,
              borderRadius: borderRadius,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? bgColor
                        : (isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText),
                  ),
                  // Designer sign-off pending: 4dp or 8dp gap?
                  const SizedBox(width: AppConstants.spacingXs),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      fontSize:   AppConstants.fontSizeMd,
                      color: isSelected
                          ? bgColor
                          : (isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
