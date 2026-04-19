// lib/widgets/search_bar.dart
//
// Universal search bar for the Khidmeti app.
// Used by: advanced_search_bar, home_categories_sheet,
//          country_code_picker, profession_picker_v2.
//
// CLASS NAME: AppSearchBar
//   (avoids collision with Material 3's built-in SearchBar widget)
//
// FOCUS RING FIX:
//   The app's InputDecorationTheme defines a focused OutlineInputBorder.
//   Without explicit overrides the blue oval renders INSIDE the container
//   whenever the field receives focus (visible bug in country picker).
//   Fix: every border variant → InputBorder.none + filled: false.
//
// VARIANTS (driven by optional callbacks):
//   simple      — search icon + field + clear
//   + camera    — adds plain camera icon before mic  (onCameraTap)
//   + voice     — adds filled-circle mic             (onVoiceTap)
//   both can be combined (advanced search bar case)
//
// DESIGN TOKENS:
//   Height  → AppConstants.buttonHeightMd  (48 dp, 8 dp grid)
//   Radius  → AppConstants.radiusMd        (12 dp)
//   Colors  → AppTheme semantic tokens only

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';

class AppSearchBar extends StatefulWidget {
  /// Text controller — caller owns creation and disposal.
  final TextEditingController controller;

  /// Placeholder text shown when the field is empty.
  final String hintText;

  /// Called on every keystroke AND when the internal clear button is tapped.
  final ValueChanged<String> onChanged;

  /// Called when the user submits via keyboard action.
  /// When provided the text-input action becomes TextInputAction.search.
  final ValueChanged<String>? onSubmitted;

  /// Theme brightness — drives all surface/text/icon colors.
  final bool isDark;

  /// External FocusNode. When null the widget manages its own.
  final FocusNode? focusNode;

  /// Requests keyboard focus immediately after mount.
  final bool autofocus;

  // ── Trailing action buttons ──────────────────────────────────────────────

  /// When provided, a plain camera icon is rendered before the mic button.
  final VoidCallback? onCameraTap;

  /// When provided, a filled-circle mic button is rendered at the trailing edge.
  final VoidCallback? onVoiceTap;

  /// Visual state of the mic button:
  ///   false → accent-colored (idle / ready)
  ///   true  → recording-red  (recording or processing)
  final bool isVoiceActive;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.isDark,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.onCameraTap,
    this.onVoiceTap,
    this.isVoiceActive = false,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode     = widget.focusNode ?? FocusNode();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _clear() {
    widget.controller.clear();
    // Programmatic clear does NOT fire TextField.onChanged — call explicitly.
    widget.onChanged('');
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final accent   = widget.isDark ? AppTheme.darkAccent       : AppTheme.lightAccent;
    final subtext  = widget.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;
    final border   = widget.isDark ? AppTheme.darkBorder        : AppTheme.lightBorder;
    final hasText  = widget.controller.text.isNotEmpty;
    final hasTrail = widget.onCameraTap != null || widget.onVoiceTap != null;

    return Container(
      height: AppConstants.buttonHeightMd,
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppTheme.darkSurface.withOpacity(0.60)
            : AppTheme.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppConstants.spacingMd),

          // Leading search icon
          Icon(AppIcons.search, size: AppConstants.iconSizeSm, color: subtext),

          const SizedBox(width: AppConstants.spacingSm),

          // Text field — ALL border variants explicitly cleared.
          Expanded(
            child: TextField(
              controller:      widget.controller,
              focusNode:       _focusNode,
              autofocus:       widget.autofocus,
              onChanged:       widget.onChanged,
              onSubmitted:     widget.onSubmitted,
              textInputAction: widget.onSubmitted != null
                  ? TextInputAction.search
                  : TextInputAction.done,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
              decoration: InputDecoration(
                hintText:  widget.hintText,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: subtext,
                ),
                // ── Focus ring fix ────────────────────────────────────────
                border:             InputBorder.none,
                enabledBorder:      InputBorder.none,
                focusedBorder:      InputBorder.none,
                disabledBorder:     InputBorder.none,
                errorBorder:        InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                // ─────────────────────────────────────────────────────────
                isDense:        true,
                contentPadding: EdgeInsets.zero,
                filled:         false,
              ),
            ),
          ),

          // Clear button — visible only when there is text.
          if (hasText)
            Semantics(
              label:  'Effacer',
              button: true,
              child: GestureDetector(
                onTap: _clear,
                child: SizedBox(
                  width:  AppConstants.buttonHeightMd,
                  height: AppConstants.buttonHeightMd,
                  child: Center(
                    child: Icon(AppIcons.close, size: 16, color: subtext),
                  ),
                ),
              ),
            ),

          // Divider — shown when there are trailing action buttons.
          if (hasTrail)
            Container(
              width:  0.5,
              height: AppConstants.iconSizeMd,
              color:  border,
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingXs,
              ),
            ),

          // Camera button (plain icon, no circle).
          if (widget.onCameraTap != null)
            Semantics(
              label:  'Recherche par image',
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onCameraTap!();
                },
                child: SizedBox(
                  width:  AppConstants.buttonHeightMd,
                  height: AppConstants.buttonHeightMd,
                  child: Center(
                    child: Icon(AppIcons.camera, size: 20, color: subtext),
                  ),
                ),
              ),
            ),

          // Mic button (filled accent circle).
          if (widget.onVoiceTap != null)
            Semantics(
              label:  'Recherche vocale',
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onVoiceTap!();
                },
                child: SizedBox(
                  width:  AppConstants.buttonHeightMd,
                  height: AppConstants.buttonHeightMd,
                  child: Center(
                    child: AnimatedContainer(
                      duration: AppConstants.animDurationMicro,
                      width:  32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isVoiceActive
                            ? AppTheme.recordingRed
                            : accent,
                      ),
                      child: Center(
                        child: Icon(
                          widget.isVoiceActive
                              ? AppIcons.micOff
                              : AppIcons.mic,
                          size:  16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (!hasTrail) const SizedBox(width: AppConstants.spacingSm),
          if (hasTrail) const SizedBox(width: AppConstants.spacingXs),
        ],
      ),
    );
  }
}
