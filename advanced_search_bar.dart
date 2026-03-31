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
const double _kActionSize  = 38.0;
const double _kAiBtnHeight = 34.0;

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
    // Original ref.watch(homeControllerProvider) rebuilt this widget on every
    // HomeState change (nearbyWorkers, workersError, isRefreshing…) even
    // though none of those fields affect this widget's output.
    final isMapFullscreen = ref.watch(
      homeControllerProvider.select((s) => s.isMapFullscreen),
    );

    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = isDark ? AppTheme.darkAccent        : AppTheme.lightAccent;
    final subtext = isDark ? AppTheme.darkSecondaryText  : AppTheme.lightSecondaryText;
    final border  = isDark ? AppTheme.darkBorder         : AppTheme.lightBorder;
    final hasText = _ctrl.text.isNotEmpty;

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
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeMd,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr('home.search_placeholder'),
                      hintStyle: TextStyle(
                        color:    subtext,
                        fontSize: AppConstants.fontSizeMd,
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
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingXs),
                        child: Icon(AppIcons.close, size: 16, color: subtext),
                      ),
                    ),
                  ),
                Container(
                  width:  0.5,
                  height: 22,
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
                      width:  _kActionSize,
                      height: _kActionSize,
                      child:  Center(
                        child: Icon(AppIcons.camera, size: 20, color: subtext),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  label:  context.tr('home.search_by_voice'),
                  button: true,
                  child: GestureDetector(
                    onTap: _openVoice,
                    child: Container(
                      width:       _kActionSize,
                      height:      _kActionSize,
                      margin:      const EdgeInsets.all(AppConstants.spacingXs),
                      decoration:  BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(AppIcons.mic, size: 18, color: Colors.white),
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
