// lib/screens/service_request/widgets/service_selection_sheet.dart
//
// CHANGE: _ServiceItem private class removed — replaced with public ServiceItem
//         imported from lib/models/service_item_model.dart.
// [C1] FIX: fontSize: AppConstants.fontSizeXs (10dp) → fontSizeXxs (11dp).
// [W2] FIX: SizedBox(height: AppConstants.spacingXs + 3) (7dp, off-grid)
//      → SizedBox(height: AppConstants.spacingSm) (8dp).
// [MANUAL] FIX: check badge icon size: 9dp → 12dp for legibility.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/service_item_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/profession_resolver.dart';

class ServiceSelectionSheet extends StatefulWidget {
  final String?              selected;
  final ValueChanged<String> onServiceSelected;

  const ServiceSelectionSheet({
    super.key,
    required this.selected,
    required this.onServiceSelected,
  });

  static void show(
    BuildContext context, {
    required String?              selected,
    required ValueChanged<String> onServiceSelected,
  }) {
    showModalBottomSheet<void>(
      context:             context,
      isScrollControlled:  true,
      backgroundColor:     Colors.transparent,
      builder: (_) => ServiceSelectionSheet(
        selected:          selected,
        onServiceSelected: onServiceSelected,
      ),
    );
  }

  @override
  State<ServiceSelectionSheet> createState() => _ServiceSelectionSheetState();
}

class _ServiceSelectionSheetState extends State<ServiceSelectionSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  late final List<ServiceItem> _allItems;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _allItems = _buildAllItems(context);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ServiceItem> _buildAllItems(BuildContext context) => [
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
            context.tr('services.${ServiceType.airConditioning}'),
            AppIcons.airConditioning),
        ServiceItem(ServiceType.gardening,
            context.tr('services.${ServiceType.gardening}'), AppIcons.gardening),
        ServiceItem(ServiceType.appliances,
            context.tr('services.${ServiceType.appliances}'), AppIcons.appliances),
        ServiceItem(ServiceType.masonry,
            context.tr('request_form.masonry'),
            AppTheme.getProfessionIcon(ServiceType.masonry)),
      ];

  List<ServiceItem> get _filtered {
    if (_query.isEmpty) return _allItems;

    final q = _query.toLowerCase();

    final labelMatches = _allItems
        .where((i) => i.label.toLowerCase().contains(q))
        .toSet();

    final resolvedType = ProfessionResolver.resolve(_query);
    final resolverMatches = resolvedType != null
        ? _allItems.where((i) => i.type == resolvedType).toSet()
        : <ServiceItem>{};

    final matchedTypes =
        {...labelMatches, ...resolverMatches}.map((i) => i.type).toSet();
    return _allItems.where((i) => matchedTypes.contains(i.type)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final isRtl   = Directionality.of(context) == TextDirection.rtl;
    final accent  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final items   = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize:     0.45,
      maxChildSize:     0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkBackground
              : AppTheme.lightBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXxl),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.spacingSm),
            Container(
              width:  AppConstants.sheetHandleWidth,
              height: AppConstants.sheetHandleHeight,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBorder.withOpacity(0.40)
                    : AppTheme.lightBorder,
                borderRadius: BorderRadius.circular(AppConstants.radiusXs),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLg),
              child: Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Expanded(
                    child: Text(
                      context.tr('request_form.section_service'),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight:    FontWeight.w700,
                            letterSpacing: isRtl ? 0.0 : -0.3,
                          ),
                    ),
                  ),
                  Semantics(
                    label:  context.tr('common.close'),
                    button: true,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width:  AppConstants.iconSizeLg,
                        height: AppConstants.iconSizeLg,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppTheme.darkSurface.withOpacity(0.60)
                              : AppTheme.lightSurfaceVariant,
                        ),
                        child: Icon(
                          AppIcons.close,
                          size:  AppConstants.iconSizeSm,
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingMd),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLg),
              child: Container(
                height: AppConstants.searchBarHeight,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurface.withOpacity(0.60)
                      : AppTheme.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: AppConstants.spacingMd),
                    Icon(AppIcons.search,
                        size:  AppConstants.iconSizeSm,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged:  (v) => setState(() => _query = v),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppTheme.darkText
                                  : AppTheme.lightText,
                            ),
                        decoration: InputDecoration(
                          border:        InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText:      context.tr('home.search_service'),
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText,
                              ),
                          isDense:        true,
                          contentPadding: EdgeInsets.zero,
                          filled:         true,
                          fillColor:      Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingMd),

            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        context.tr('home.no_service_found'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText,
                            ),
                      ),
                    )
                  : GridView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.paddingLg,
                        0,
                        AppConstants.paddingLg,
                        AppConstants.paddingLg,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:   4,
                        mainAxisSpacing:  AppConstants.spacingMd,
                        crossAxisSpacing: AppConstants.spacingMd,
                        childAspectRatio: 0.82,
                      ),
                      itemCount:   items.length,
                      itemBuilder: (_, i) => _ServiceTile(
                        item:       items[i],
                        isSelected: widget.selected == items[i].type,
                        isDark:     isDark,
                        accent:     accent,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onServiceSelected(items[i].type);
                          Navigator.pop(context);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final ServiceItem  item;
  final bool         isSelected;
  final bool         isDark;
  final Color        accent;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Semantics(
      button:   true,
      label:    item.label,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width:    AppConstants.categoryTileIconSize,
                  height:   AppConstants.categoryTileIconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? color.withOpacity(isDark ? 0.24 : 0.15)
                        : color.withOpacity(isDark ? 0.12 : 0.09),
                    border: isSelected
                        ? Border.all(
                            color: color.withOpacity(0.55),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Icon(
                    item.icon,
                    color: isSelected
                        ? color
                        : color.withOpacity(isDark ? 0.85 : 0.75),
                    size: AppConstants.iconSizeMd,
                  ),
                ),

                if (isSelected)
                  Positioned(
                    bottom: -2,
                    right:  -2,
                    child: Container(
                      width:  16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBackground
                              : AppTheme.lightBackground,
                          width: 1.5,
                        ),
                      ),
                      // [MANUAL] FIX: check badge icon 9dp → 12dp for legibility
                      child: const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),

            // [W2] FIX: SizedBox(height: spacingXs + 3) (7dp) → spacingSm (8dp)
            const SizedBox(height: AppConstants.spacingSm),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingXs),
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? color
                          : (isDark
                              ? AppTheme.darkText
                              : AppTheme.lightSecondaryText),
                      // [C1] FIX: fontSizeXs (10dp) → fontSizeXxs (11dp)
                      fontSize: AppConstants.fontSizeXxs,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      height: 1.2,
                    ),
                textAlign: TextAlign.center,
                maxLines:  2,
                overflow:  TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
