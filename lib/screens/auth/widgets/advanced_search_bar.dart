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

// [AUTO FIX S2]: _kBarHeight and _kTapZoneSize were raw 48.0 literals.
// Now both reference AppConstants.buttonHeightMd — the single source of truth
// for the 48dp interactive-element height. This also resolves the 44dp vs 48dp
// search-bar height split with home_categories_sheet (which now also uses
// AppConstants.buttonHeightMd via the updated searchBarHeight token).
const double _kBarHeight   = AppConstants.buttonHeightMd;
// [W1 FIX]: _kActionSize 38.0 → 40.0 (8dp-grid snap).
// [UI-FIX TOUCH]: Visual size of camera/mic icons kept at 40dp.
// The GestureDetector tap zone is enlarged to 48×48 via an outer SizedBox
// so both the visual and the tap area are now correct.
const double _kActionSize  = 40.0;
const double _kTapZoneSize = AppConstants.buttonHeightMd;
// [W1 FIX]: _kAiBtnHeight 34.0 → 32.0 (8dp-grid snap).
const double _kAiBtnHeight = 32.0;
// [S3 FIX]: was bare `size: 11` — off every standard scale (iconSizeXs=16).
// 12dp is the nearest on-grid value for a badge icon inside a 20dp container.
const double _kAiIconBadgeSize = 12.0;

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
    final isMapFullscreen = ref.watch(
      homeControllerProvider.select((s) => s.isMapFullscreen),
    );

    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = isDark ? AppTheme.darkAccent        : AppTheme.lightAccent;
    final subtext = isDark ? AppTheme.darkSecondaryText  : AppTheme.lightSecondaryText;
    final border  = isDark ? AppTheme.darkBorder         : AppTheme.lightBorder;
    final hasText = _ctrl.text.isNotEmpty;

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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr('home.search_placeholder'),
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
          SizedBox(
            height: _kTapZoneSize,
            width:  double.infinity,
            child: Center(
              child: Align(
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
                            child: Center(
                              child: Icon(
                                AppIcons.ai,
                                size:  _kAiIconBadgeSize,
                                color: onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingSm),
                          // [AUTO FIX C2]: was TextStyle(fontSize: AppConstants.fontSizeSm,
                          // fontWeight: FontWeight.w500, color: accent) — inline TextStyle
                          // that bypasses the textTheme, rendering at 12dp while
                          // textTheme.labelSmall is 11dp. Now uses labelSmall?.copyWith(...)
                          // for consistency with ai_example_chips.dart and every other
                          // label in this file.
                          Text(
                            context.tr('home.ai_search_label'),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
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
