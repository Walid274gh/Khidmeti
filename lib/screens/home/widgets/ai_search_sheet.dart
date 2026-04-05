// lib/screens/home/widgets/ai_search_sheet.dart
// FIX (Structure): _ResultCard extracted → ai_result_card.dart
//                  _ExampleChips extracted → ai_example_chips.dart
//                  _AiSearchSheetState._examples dead code removed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/search_intent.dart';
import '../../../providers/home_search_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'ai_result_card.dart';
import 'ai_example_chips.dart';

class AiSearchSheet extends ConsumerStatefulWidget {
  const AiSearchSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => const AiSearchSheet(),
    );
  }

  @override
  ConsumerState<AiSearchSheet> createState() => _AiSearchSheetState();
}

class _AiSearchSheetState extends ConsumerState<AiSearchSheet> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  // FIX (Dead code removed): _examples static const was declared here but
  // never referenced — AiExampleChips owns its own list in its own file.
  // Removed to eliminate confusion and dead code warning.

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    _focus.unfocus();
    ref.read(homeSearchControllerProvider.notifier).submitSearch(text);
  }

  void _reset() {
    ref.read(homeSearchControllerProvider.notifier).reset();
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final accent      = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final searchState = ref.watch(homeSearchControllerProvider);
    final isLoading   = searchState.isLoading;
    final hasResult   = searchState.hasResults;
    final hasError    = searchState.hasError;
    final intent      = searchState.lastIntent;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkBackground
              : AppTheme.lightBackground,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusXxl)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppConstants.spacingSm),
              Center(
                child: Container(
                  width:  AppConstants.sheetHandleWidth,
                  height: AppConstants.sheetHandleHeight,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBorder
                        : AppTheme.lightBorder,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusXs),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLg),
                child: Row(
                  children: [
                    Container(
                      width:  AppConstants.iconContainerSm,
                      height: AppConstants.iconContainerSm,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                      child: const Center(
                        child: Icon(AppIcons.ai, size: 14,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        context.tr('home.ai_search_title'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    // [UI-FIX TOUCH]: outer 48×48 SizedBox is the tap zone;
                    // inner Container stays at iconContainerMd (32dp) visually.
                    Semantics(
                      label:  context.tr('common.close'),
                      button: true,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: SizedBox(
                          width:  AppConstants.buttonHeightMd,
                          height: AppConstants.buttonHeightMd,
                          child: Center(
                            child: Container(
                              width:  AppConstants.iconContainerMd,
                              height: AppConstants.iconContainerMd,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppTheme.darkSurface
                                    : AppTheme.lightSurfaceVariant,
                              ),
                              child: Center(
                                child: Icon(AppIcons.close,
                                    size: 16,
                                    color: isDark
                                        ? AppTheme.darkSecondaryText
                                        : AppTheme.lightSecondaryText),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              if (hasResult && intent != null && !isLoading) ...[
                // FIX (Structure): AiResultCard — extracted widget
                AiResultCard(intent: intent, isDark: isDark),
                const SizedBox(height: AppConstants.spacingMd),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLg),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reset,
                          child: Text(context.tr('common.edit')),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            ref
                                .read(homeSearchControllerProvider.notifier)
                                .applyToMap();
                            Navigator.pop(context);
                          },
                          child: Text(
                              context.tr('home.ai_search_see_workers')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLg),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLg),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurface
                          : AppTheme.lightSurfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusLg),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : AppTheme.lightBorder,
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller:   _ctrl,
                      focusNode:    _focus,
                      autofocus:    true,
                      maxLines:     4,
                      minLines:     3,
                      enabled:      !isLoading,
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeMd,
                        color: isDark
                            ? AppTheme.darkText
                            : AppTheme.lightText,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText:  context.tr('home.ai_search_hint'),
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                          fontSize: AppConstants.fontSizeMd,
                          height:   1.5,
                        ),
                        border:         InputBorder.none,
                        contentPadding:
                            const EdgeInsets.all(AppConstants.paddingMd),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingXs),

                if (hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingLg),
                    child: Text(
                      context.tr('home.search_error'),
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeSm,
                        color: isDark
                            ? AppTheme.darkError
                            : AppTheme.lightError,
                      ),
                    ),
                  ),

                const SizedBox(height: AppConstants.spacingXs),

                // FIX (Structure): AiExampleChips — extracted widget
                AiExampleChips(
                  isDark: isDark,
                  onTap: (text) {
                    _ctrl.text = text;
                    _ctrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: text.length));
                  },
                ),

                const SizedBox(height: AppConstants.spacingMd),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLg),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width:  20,
                            height: 20,
                            child:  CircularProgressIndicator(
                              strokeWidth: 2,
                              color:       Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(AppIcons.ai, size: 16),
                              const SizedBox(width: AppConstants.spacingSm),
                              Text(context.tr('home.ai_search_submit')),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
