// lib/widgets/glass_navigation_bars.dart

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN CONSTANTS  (local — not exposed outside this file)
// ─────────────────────────────────────────────────────────────────────────────

const double _kPillHeight   = 58.0;
const double _kPillInactive = 58.0;
const double _kPillActive   = 148.0;
const double _kPillGap      = 8.0;
const double _kPillHPad     = 14.0;
const double _kIconLabelGap = 8.0;
const double _kIconSize     = 22.0;
const double _kLabelArea    = 98.0;

const Duration _kExpandDur  = Duration(milliseconds: 380);
const Duration _kFadeDurIn  = Duration(milliseconds: 200);
const Duration _kFadeDurOut = Duration(milliseconds: 80);
const Curve    _kSpring     = Cubic(0.34, 1.4, 0.64, 1);

// ─────────────────────────────────────────────────────────────────────────────
// Internal data model
// ─────────────────────────────────────────────────────────────────────────────

class _NavItemData {
  final IconData icon;
  final IconData iconOutlined;
  final String   label;
  final int      index;
  const _NavItemData({
    required this.icon,
    required this.iconOutlined,
    required this.label,
    required this.index,
  });
}

// ============================================================================
// USER NAVIGATION BAR  (2 tabs: Home · Profile)
// ============================================================================

class UserGlassNavigationBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const UserGlassNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _NavShell(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        _NavItemData(icon: AppIcons.home,    iconOutlined: AppIcons.homeOutlined,    label: context.tr('nav.home'),    index: 0),
        _NavItemData(icon: AppIcons.profile, iconOutlined: AppIcons.profileOutlined, label: context.tr('nav.profile'), index: 1),
      ],
    );
  }
}

// ============================================================================
// WORKER NAVIGATION BAR  (3 tabs: Home · Jobs · Profile)
// ============================================================================

class WorkerGlassNavigationBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const WorkerGlassNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _NavShell(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        _NavItemData(icon: AppIcons.home,    iconOutlined: AppIcons.homeOutlined,    label: context.tr('nav.home'),    index: 0),
        _NavItemData(icon: AppIcons.jobs,    iconOutlined: AppIcons.jobsOutlined,    label: context.tr('nav.jobs'),    index: 1),
        _NavItemData(icon: AppIcons.profile, iconOutlined: AppIcons.profileOutlined, label: context.tr('nav.profile'), index: 2),
      ],
    );
  }
}

// ============================================================================
// _NavShell
//
//  CRITICAL FIX: Scaffold.bottomNavigationBar measures its child height to
//  reserve space at the bottom of the body. Without a fixed height the Align
//  widget expands to fill the entire screen and covers all content.
//
//  Solution: SizedBox pins the slot to exactly pill (58) + bottom margin (10)
//  = 68 px — identical to the original navBarHeight — so the body is intact.
// ============================================================================

class _NavShell extends StatelessWidget {
  final List<_NavItemData>  items;
  final int                 currentIndex;
  final void Function(int)  onTap;
  const _NavShell({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: _kPillHeight + AppConstants.navBarMarginB + 12.0,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.navBarMarginH,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: _kPillGap),
                  _NavPill(
                    data:         items[i],
                    currentIndex: currentIndex,
                    onTap:        onTap,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _NavPill
// ============================================================================

class _NavPill extends StatelessWidget {
  final _NavItemData       data;
  final int                currentIndex;
  final void Function(int) onTap;
  const _NavPill({
    required this.data,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected   = currentIndex == data.index;
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final accent          = isDark ? AppTheme.darkAccent         : AppTheme.lightAccent;
    final surface         = isDark ? AppTheme.darkSurface        : AppTheme.lightSurface;
    final border          = isDark ? AppTheme.darkBorder         : AppTheme.lightBorder;
    final activeSurface   = isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant;
    final iconInactive    = isDark ? AppTheme.darkSecondaryText  : AppTheme.lightSecondaryText;

    return Semantics(
      label:    data.label,
      selected: isSelected,
      button:   true,
      child: GestureDetector(
        onTap:    () => onTap(data.index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration:     _kExpandDur,
          curve:        _kSpring,
          width:        isSelected ? _kPillActive : _kPillInactive,
          height:       _kPillHeight,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: isSelected ? activeSurface : surface,
            borderRadius: BorderRadius.circular(AppConstants.navBarRadius),
            border: Border.all(
              color: isSelected ? accent : border,
              width: AppConstants.cardBorderWidth,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kPillHPad),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Icon(
                    isSelected ? data.icon : data.iconOutlined,
                    key:   ValueKey(isSelected),
                    size:  _kIconSize,
                    color: isSelected ? accent : iconInactive,
                  ),
                ),

                AnimatedContainer(
                  duration:     _kExpandDur,
                  curve:        _kSpring,
                  width:        isSelected ? _kLabelArea : 0.0,
                  clipBehavior: Clip.hardEdge,
                  decoration:   const BoxDecoration(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: _kIconLabelGap),
                      AnimatedOpacity(
                        opacity:  isSelected ? 1.0 : 0.0,
                        duration: isSelected ? _kFadeDurIn : _kFadeDurOut,
                        child: Text(
                          data.label,
                          style: TextStyle(
                            fontSize:   AppConstants.fontSizeCaption,
                            fontWeight: FontWeight.w600,
                            color:      accent,
                            height:     1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                        ),
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
