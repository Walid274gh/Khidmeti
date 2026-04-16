// lib/screens/auth/widgets/profession_picker_v2.dart
//
// SCALABLE PROFESSION PICKER — supports 8 to 100+ professions.
//
// Layout strategy:
//   ≤12 professions  → 4-col grid (no search bar, no categories)
//   13–24 professions → 4-col grid + search bar at top
//   25+  professions  → grouped list by category + search bar + category tabs
//
// Data source: professionsProvider (API-driven, 24h cache, kDefaultProfessions offline)
// Voice button: always visible (VoiceProfessionButton)
// Auto-select: animates highlight + scrolls to selected profession

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profession_model.dart';
import '../../../providers/professions_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ─────────────────────────────────────────────────────────────────────────────

class ProfessionPickerV2 extends ConsumerStatefulWidget {
  /// Currently selected profession key, or null.
  final String? selectedKey;

  /// Called when user selects/deselects a profession.
  final ValueChanged<String?> onSelected;

  /// Whether to show the voice detection button.
  final bool showVoiceButton;

  const ProfessionPickerV2({
    super.key,
    required this.selectedKey,
    required this.onSelected,
    this.showVoiceButton = false,
  });

  @override
  ConsumerState<ProfessionPickerV2> createState() => ProfessionPickerV2State();
}

class ProfessionPickerV2State extends ConsumerState<ProfessionPickerV2>
    with TickerProviderStateMixin {

  final TextEditingController _searchCtrl  = TextEditingController();
  final ScrollController       _scrollCtrl  = ScrollController();

  Timer?  _debounce;
  String  _query          = '';
  String? _activeCategoryKey;

  late final AnimationController _highlightController;
  String? _animatedKey;

  @override
  void initState() {
    super.initState();

    _highlightController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    _highlightController.dispose();
    super.dispose();
  }

  // ── Public: auto-select from voice detection ───────────────────────────────

  /// Programmatically selects a profession key with animated highlight.
  void autoSelect(String professionKey) {
    if (!mounted) return;
    widget.onSelected(professionKey);
    setState(() {
      _animatedKey = professionKey;
      _query       = '';
      _searchCtrl.clear();
    });

    _highlightController.reset();
    _highlightController.forward().then((_) {
      if (mounted) setState(() => _animatedKey = null);
    });
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<ProfessionModel> _filter(List<ProfessionModel> all) {
    List<ProfessionModel> result = all.where((p) => p.isActive).toList();

    if (_activeCategoryKey != null) {
      result = result.where((p) => p.categoryKey == _activeCategoryKey).toList();
    }

    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      result = result.where((p) =>
        p.label.toLowerCase().contains(q) ||
        p.key.toLowerCase().contains(q)
      ).toList();
    }

    return result..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  // ── Layout selection ───────────────────────────────────────────────────────

  _Layout _layoutFor(int count) {
    if (count <= 12) return _Layout.gridSimple;
    if (count <= 24) return _Layout.gridWithSearch;
    return _Layout.groupedList;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark        = Theme.of(context).brightness == Brightness.dark;
    final professions   = ref.watch(professionsProvider);

    return professions.when(
      loading: () => const _LoadingGrid(),
      error:   (_, __) => _ErrorWidget(
        isDark:  isDark,
        onRetry: () => ref.invalidate(professionsProvider),
      ),
      data: (professions) {
        final allActive = professions.where((p) => p.isActive).toList();
        final layout    = _layoutFor(allActive.length);
        final filtered  = _filter(professions);

        return _PickerBody(
          all:             allActive,
          filtered:        filtered,
          layout:          layout,
          isDark:          isDark,
          selectedKey:     widget.selectedKey,
          animatedKey:     _animatedKey,
          highlightAnim:   _highlightController,
          searchCtrl:      _searchCtrl,
          scrollCtrl:      _scrollCtrl,
          query:           _query,
          activeCategoryKey: _activeCategoryKey,
          showSearch:      layout != _Layout.gridSimple,
          onSearchChanged: (value) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _query = value);
            });
          },
          onCategorySelected: (key) =>
              setState(() => _activeCategoryKey = key),
          onTap: (key) {
            HapticFeedback.selectionClick();
            widget.onSelected(widget.selectedKey == key ? null : key);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout enum
// ─────────────────────────────────────────────────────────────────────────────

enum _Layout { gridSimple, gridWithSearch, groupedList }

// ─────────────────────────────────────────────────────────────────────────────
// Main picker body
// ─────────────────────────────────────────────────────────────────────────────

class _PickerBody extends StatelessWidget {
  final List<ProfessionModel>   all;
  final List<ProfessionModel>   filtered;
  final _Layout                 layout;
  final bool                    isDark;
  final String?                 selectedKey;
  final String?                 animatedKey;
  final AnimationController     highlightAnim;
  final TextEditingController   searchCtrl;
  final ScrollController        scrollCtrl;
  final String                  query;
  final String?                 activeCategoryKey;
  final bool                    showSearch;
  final ValueChanged<String>    onSearchChanged;
  final ValueChanged<String?>   onCategorySelected;
  final ValueChanged<String>    onTap;

  const _PickerBody({
    required this.all,
    required this.filtered,
    required this.layout,
    required this.isDark,
    required this.selectedKey,
    required this.animatedKey,
    required this.highlightAnim,
    required this.searchCtrl,
    required this.scrollCtrl,
    required this.query,
    required this.activeCategoryKey,
    required this.showSearch,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar (when needed)
        if (showSearch) ...[
          _SearchBar(
            controller: searchCtrl,
            isDark:     isDark,
            onChanged:  onSearchChanged,
          ),
          const SizedBox(height: AppConstants.spacingSm),
        ],

        // Category tabs (for grouped list layout)
        if (layout == _Layout.groupedList) ...[
          _CategoryTabs(
            all:            all,
            isDark:         isDark,
            activeKey:      activeCategoryKey,
            onSelected:     onCategorySelected,
          ),
          const SizedBox(height: AppConstants.spacingMd),
        ],

        // Grid
        if (filtered.isEmpty)
          _EmptySearch(isDark: isDark)
        else
          GridView.builder(
            controller:  scrollCtrl,
            shrinkWrap:  true,
            physics:     const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:   4,
              crossAxisSpacing: AppConstants.spacingChipGap,
              mainAxisSpacing:  AppConstants.spacingChipGap,
              childAspectRatio: 0.85,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, index) {
              final profession = filtered[index];
              final isSelected = selectedKey == profession.key;
              final isAnimated = animatedKey == profession.key;

              return _ProfessionTile(
                profession:   profession,
                isSelected:   isSelected,
                isAnimated:   isAnimated,
                highlightAnim: highlightAnim,
                isDark:       isDark,
                onTap:        () => onTap(profession.key),
              );
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profession tile
// ─────────────────────────────────────────────────────────────────────────────

class _ProfessionTile extends StatelessWidget {
  final ProfessionModel   profession;
  final bool              isSelected;
  final bool              isAnimated;
  final AnimationController highlightAnim;
  final bool              isDark;
  final VoidCallback      onTap;

  const _ProfessionTile({
    required this.profession,
    required this.isSelected,
    required this.isAnimated,
    required this.highlightAnim,
    required this.isDark,
    required this.onTap,
  });

  IconData _resolveIcon() {
    return AppTheme.getProfessionIcon(profession.key);
  }

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Semantics(
      button:   true,
      selected: isSelected,
      label:    profession.label,
      child: GestureDetector(
        onTap: onTap,
        child: isAnimated
            ? AnimatedBuilder(
                animation: highlightAnim,
                builder: (_, child) => _TileContent(
                  profession:   profession,
                  isSelected:   isSelected,
                  isDark:       isDark,
                  pulseValue:   Curves.elasticOut.transform(highlightAnim.value),
                  icon:         _resolveIcon(),
                  accent:       accent,
                ),
              )
            : _TileContent(
                profession: profession,
                isSelected: isSelected,
                isDark:     isDark,
                pulseValue: 1.0,
                icon:       _resolveIcon(),
                accent:     accent,
              ),
      ),
    );
  }
}

class _TileContent extends StatelessWidget {
  final ProfessionModel profession;
  final bool            isSelected;
  final bool            isDark;
  final double          pulseValue;
  final IconData        icon;
  final Color           accent;

  const _TileContent({
    required this.profession,
    required this.isSelected,
    required this.isDark,
    required this.pulseValue,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + (pulseValue - 1.0) * 0.05;

    return AnimatedContainer(
      duration: AppConstants.animDurationMicro,
      transform: Matrix4.identity()
        ..translate(24.0 * (1 - scale), 24.0 * (1 - scale))
        ..scale(scale),
      decoration: BoxDecoration(
        color: isSelected
            ? accent.withOpacity(isDark ? 0.20 : 0.12)
            : (isDark ? AppTheme.darkTileFill : AppTheme.lightTileFill),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isSelected
              ? accent
              : (isDark ? AppTheme.darkTileBorder : AppTheme.lightTileBorder),
          width: isSelected
              ? AppConstants.borderWidthSelected
              : AppConstants.borderWidthDefault,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size:  AppConstants.iconSizeMd,
                color: isSelected
                    ? accent
                    : (isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText),
              ),
              // Check badge for selected
              if (isSelected)
                Positioned(
                  right: -6,
                  top:   -6,
                  child: Container(
                    width:  16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBackground
                            : AppTheme.lightBackground,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size:  10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingXs),

          // Label
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingXs,
            ),
            child: Text(
              profession.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? accent
                    : (isDark ? AppTheme.darkText : AppTheme.lightSecondaryText),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool                  isDark;
  final ValueChanged<String>  onChanged;

  const _SearchBar({
    required this.controller,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.searchBarHeight,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppConstants.spacingMd),
          Icon(
            AppIcons.search,
            size:  AppConstants.iconSizeSm,
            color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged:  onChanged,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
              decoration: InputDecoration(
                border:         InputBorder.none,
                hintText:       context.tr('common.search'),
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
                isDense:        true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon:  const Icon(AppIcons.close, size: 16),
              color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category tabs
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTabs extends StatelessWidget {
  final List<ProfessionModel> all;
  final bool                  isDark;
  final String?               activeKey;
  final ValueChanged<String?> onSelected;

  const _CategoryTabs({
    required this.all,
    required this.isDark,
    required this.activeKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Collect unique categories preserving order
    final seen = <String>{};
    final categories = <MapEntry<String, String>>[]; // key → label
    for (final p in all) {
      if (seen.add(p.categoryKey)) {
        categories.add(MapEntry(p.categoryKey, p.categoryLabel));
      }
    }

    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: AppConstants.spacingXs),
            child: _CategoryChip(
              label:      context.tr('home.filter_all'),
              isSelected: activeKey == null,
              accent:     accent,
              isDark:     isDark,
              onTap:      () => onSelected(null),
            ),
          ),
          ...categories.map((e) => Padding(
            padding: const EdgeInsets.only(right: AppConstants.spacingXs),
            child: _CategoryChip(
              label:      e.value,
              isSelected: activeKey == e.key,
              accent:     accent,
              isDark:     isDark,
              onTap:      () => onSelected(
                activeKey == e.key ? null : e.key,
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String     label;
  final bool       isSelected;
  final Color      accent;
  final bool       isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button:   true,
      selected: isSelected,
      label:    label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppConstants.animDurationMicro,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd,
          ),
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
            border: Border.all(
              color: isSelected
                  ? accent
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize:   AppConstants.fontSizeSm,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.darkText : AppTheme.lightText),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / error / empty states
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap:  true,
      physics:     const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   4,
        crossAxisSpacing: AppConstants.spacingChipGap,
        mainAxisSpacing:  AppConstants.spacingChipGap,
        childAspectRatio: 0.85,
      ),
      itemCount: 8,
      itemBuilder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkTileFill : AppTheme.lightTileFill,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        );
      },
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final bool         isDark;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr('errors.network'),
          style: TextStyle(
            color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        TextButton(
          onPressed: onRetry,
          child: Text(context.tr('common.retry')),
        ),
      ],
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final bool isDark;
  const _EmptySearch({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Text(
          context.tr('home.no_service_found'),
          style: TextStyle(
            color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
          ),
        ),
      ),
    );
  }
}
