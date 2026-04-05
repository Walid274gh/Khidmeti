// lib/screens/home/widgets/advanced_search_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/home_controller.dart';
import '../../../providers/home_search_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/profession_resolver.dart';
import 'ai_search_sheet.dart';
import 'image_search_sheet.dart';
import 'voice_search_sheet.dart';

const double _kBarHeight   = 48.0;
// [W1 FIX]: _kActionSize 38.0 → 40.0 (8dp-grid snap).
// [UI-FIX TOUCH]: Visual size of camera/mic icons kept at 40dp.
// The GestureDetector tap zone is enlarged to 48×48 via an outer SizedBox
// so both the visual and the tap area are now correct.
const double _kActionSize  = 40.0;
const double _kTapZoneSize = 48.0;
// [W1 FIX]: _kAiBtnHeight 34.0 → 32.0 (8dp-grid snap).
const double _kAiBtnHeight = 32.0;

class AdvancedSearchBar extends ConsumerStatefulWidget {
  const AdvancedSearchBar({super.key});

  @override
  ConsumerState<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends ConsumerState<AdvancedSearchBar> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) => setState(() {});

  // FIX (Bug — toggle semantics, Critical P0):
  // The original code called toggleServiceFilter() which CLEARS the filter
  // when the same profession is already active. Concrete bug: user types
  // "blombi", opens the map, comes back, types "blombi" again →
  // toggleServiceFilter('plumber') sees plumber == activeFilter → sets next=null
  // → filter CLEARED → map shows all workers instead of plumbers.
  // Fix: use setServiceFilter() which always SETS — never toggles.
  //
  // FIX (UX — silent failure, P1 Marketplace):
  // When ProfessionResolver.resolve() returns null (e.g. "j'ai un problème
  // avec ma porte"), the old code returned silently. User had no feedback.
  // Fix: show a SnackBar directing to "Recherche IA" for unrecognised queries.
  void _onSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    HapticFeedback.lightImpact();
    _focus.unfocus();

    final profession = ProfessionResolver.resolve(trimmed);

    if (profession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('home.search_no_match_hint'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  AiSearchSheet.show(context);
                },
                child: Text(
                  context.tr('home.ai_search_label'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor:
              Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkSurface
                  : AppTheme.lightText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          margin: const EdgeInsets.all(AppConstants.paddingMd),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // FIX: setServiceFilter() — direct set, no toggle semantics.
    final homeNotifier = ref.read(homeControllerProvider.notifier);
    homeNotifier.setServiceFilter(profession);
    homeNotifier.enterMapFullscreen();
  }

  void _onClear() {
    _ctrl.clear();
    _focus.unfocus();
    ref.read(homeSearchControllerProvider.notifier).reset();
    setState(() {});
  }

  void _openAiSearch() {
    HapticFeedback.selectionClick();
    _focus.unfocus();
    AiSearchSheet.show(context);
  }

  void _openVoice() {
    HapticFeedback.selectionClick();
    _focus.unfocus();
    VoiceSearchSheet.show(context);
  }

  void _openCamera() {
    HapticFeedback.selectionClick();
    _focus.unfocus();
    ImageSearchSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    // FIX (Rebuild scope): select() limits rebuilds to isMapFullscreen only.
    final isMapFullscreen = ref.watch(
      homeControllerProvider.select((s) => s.isMapFullscreen),
    );

    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = isDark ? AppTheme.darkAccent        : AppTheme.lightAccent;
    final subtext = isDark ? AppTheme.darkSecondaryText  : AppTheme.lightSecondaryText;
    final border  = isDark ? AppTheme.darkBorder         : AppTheme.lightBorder;
    final hasText = _ctrl.text.isNotEmpty;

    // [C1 FIX]: resolved once in build so the mic icon can reference it
    // without being const — colorScheme.onPrimary is a runtime value.
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    if (isMapFullscreen) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: _kBarHeight,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurface.withOpacity(0.60)
                  : AppTheme.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
              border: Border.all(color: border, width: 0.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppConstants.spacingMd),
                Icon(AppIcons.search, size: 18, color: subtext),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode:  _focus,
                    // [C2 FIX]: was inline TextStyle(fontSize: fontSizeMd, ...) —
                    // bypasses textTheme. Replaced with bodyMedium?.copyWith(...)
                    // so the input text participates in the design-system type scale.
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr('home.search_placeholder'),
                      // [C2 FIX]: was inline TextStyle(color: subtext, fontSize: fontSizeMd).
                      // Replaced with bodyMedium?.copyWith(...).
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: subtext,
                      ),
                      border:         InputBorder.none,
                      enabledBorder:  InputBorder.none,
                      focusedBorder:  InputBorder.none,
                      isDense:        true,
                      contentPadding: EdgeInsets.zero,
                      filled:         true,
                      fillColor:      Colors.transparent,
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged:   _onTextChanged,
                    onSubmitted: _onSubmitted,
                  ),
                ),
                // [T1 FIX]: clear button now uses the same 48×48 tap-zone
                // pattern as camera/mic — SizedBox outer + Center inner.
                if (hasText)
                  Semantics(
                    label:  context.tr('common.close'),
                    button: true,
                    child: GestureDetector(
                      onTap: _onClear,
                      child: SizedBox(
                        width:  _kTapZoneSize,
                        height: _kTapZoneSize,
                        child: Center(
                          child: Icon(AppIcons.close, size: 16, color: subtext),
                        ),
                      ),
                    ),
                  ),
                Container(
                  width:  0.5,
                  height: AppConstants.iconSizeMd,
                  color:  border,
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingXs),
                ),
                // [UI-FIX TOUCH]: outer SizedBox sets 48×48 tap zone;
                // inner SizedBox keeps the visual at _kActionSize (40dp).
                Semantics(
                  label:  context.tr('home.search_by_image'),
                  button: true,
                  child: GestureDetector(
                    onTap: _openCamera,
                    child: SizedBox(
                      width:  _kTapZoneSize,
                      height: _kTapZoneSize,
                      child: Center(
                        child: SizedBox(
                          width:  _kActionSize,
                          height: _kActionSize,
                          child: Center(
                            child: Icon(AppIcons.camera, size: 20, color: subtext),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // [UI-FIX TOUCH]: same pattern for mic/voice button.
                Semantics(
                  label:  context.tr('home.search_by_voice'),
                  button: true,
                  child: GestureDetector(
                    onTap: _openVoice,
                    child: SizedBox(
                      width:  _kTapZoneSize,
                      height: _kTapZoneSize,
                      child: Center(
                        child: Container(
                          width:      _kActionSize,
                          height:     _kActionSize,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          // [C1 FIX]: was const Icon(..., color: Colors.white) —
                          // hardcoded primitive. Replaced with onPrimary from
                          // colorScheme — semantically correct for icon on
                          // accent-filled container. const removed because
                          // onPrimary is a runtime value.
                          child: Center(
                            child: Icon(AppIcons.mic, size: 18, color: onPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingXs),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              label:  context.tr('home.ai_search_label'),
              button: true,
              child: GestureDetector(
                onTap: _openAiSearch,
                child: Container(
                  height: _kAiBtnHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMd,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusCircle),
                    border: Border.all(
                      color: accent.withOpacity(isDark ? 0.30 : 0.25),
                      width: 0.5,
                    ),
                    color: accent.withOpacity(isDark ? 0.08 : 0.06),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width:  20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                        child: const Center(
                          child: Icon(AppIcons.ai, size: 11,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Text(
                        context.tr('home.ai_search_label'),
                        style: TextStyle(
                          fontSize:   AppConstants.fontSizeSm,
                          fontWeight: FontWeight.w500,
                          color:      accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
