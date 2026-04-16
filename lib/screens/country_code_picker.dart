// lib/screens/auth/widgets/country_code_picker.dart
//
// Bottom sheet country selector.
// DZ (Algeria) is always first and visually separated from the rest.
// Filtered in-place with a debounced search field.
// Returns a [CountryCode] record via Navigator.pop.
//
// FIX: `const CountryCode kDefaultCountry = _kCountries[0]` was illegal —
//   Dart does not support compile-time const indexing of a List literal.
//   Replaced with an explicit inline const, which is semantically identical
//   and compiles without error.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/sheet_chrome.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a dialling country with its flag, ISO code, and dial prefix.
class CountryCode {
  final String flag;
  final String code;      // ISO 3166-1 alpha-2: DZ, FR, US …
  final String dialCode;  // E.164 prefix:  +213, +33, +1 …
  final String name;

  const CountryCode({
    required this.flag,
    required this.code,
    required this.dialCode,
    required this.name,
  });
}

// Curated list — DZ first, then alphabetical by name.
// Keep this const so the list is allocated once and shared.
const List<CountryCode> _kCountries = [
  CountryCode(flag: '🇩🇿', code: 'DZ', dialCode: '+213', name: 'Algérie'),
  CountryCode(flag: '🇲🇦', code: 'MA', dialCode: '+212', name: 'Maroc'),
  CountryCode(flag: '🇹🇳', code: 'TN', dialCode: '+216', name: 'Tunisie'),
  CountryCode(flag: '🇱🇾', code: 'LY', dialCode: '+218', name: 'Libye'),
  CountryCode(flag: '🇲🇷', code: 'MR', dialCode: '+222', name: 'Mauritanie'),
  CountryCode(flag: '🇫🇷', code: 'FR', dialCode: '+33',  name: 'France'),
  CountryCode(flag: '🇧🇪', code: 'BE', dialCode: '+32',  name: 'Belgique'),
  CountryCode(flag: '🇨🇭', code: 'CH', dialCode: '+41',  name: 'Suisse'),
  CountryCode(flag: '🇩🇪', code: 'DE', dialCode: '+49',  name: 'Allemagne'),
  CountryCode(flag: '🇬🇧', code: 'GB', dialCode: '+44',  name: 'Royaume-Uni'),
  CountryCode(flag: '🇺🇸', code: 'US', dialCode: '+1',   name: 'États-Unis'),
  CountryCode(flag: '🇨🇦', code: 'CA', dialCode: '+1',   name: 'Canada'),
  CountryCode(flag: '🇪🇸', code: 'ES', dialCode: '+34',  name: 'Espagne'),
  CountryCode(flag: '🇮🇹', code: 'IT', dialCode: '+39',  name: 'Italie'),
  CountryCode(flag: '🇵🇹', code: 'PT', dialCode: '+351', name: 'Portugal'),
  CountryCode(flag: '🇳🇱', code: 'NL', dialCode: '+31',  name: 'Pays-Bas'),
  CountryCode(flag: '🇸🇦', code: 'SA', dialCode: '+966', name: 'Arabie saoudite'),
  CountryCode(flag: '🇦🇪', code: 'AE', dialCode: '+971', name: 'Émirats arabes unis'),
  CountryCode(flag: '🇪🇬', code: 'EG', dialCode: '+20',  name: 'Égypte'),
  CountryCode(flag: '🇸🇳', code: 'SN', dialCode: '+221', name: 'Sénégal'),
];

// FIX: was `const CountryCode kDefaultCountry = _kCountries[0]`
//
// Dart evaluates const expressions at compile time. Indexing a List with []
// is a runtime operation even when both the list and index are const — the
// language spec does not define [] as a const-eligible operation.
//
// Solution: inline the first entry explicitly. The value is identical to
// _kCountries[0] and remains in sync as long as DZ stays at position 0.
// If the default country ever changes, update this constant together with
// the list ordering.
const CountryCode kDefaultCountry = CountryCode(
  flag:     '🇩🇿',
  code:     'DZ',
  dialCode: '+213',
  name:     'Algérie',
);

// ─────────────────────────────────────────────────────────────────────────────
// Public helper
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the country picker bottom sheet and resolves with the selected
/// [CountryCode], or `null` when the user dismisses without selecting.
Future<CountryCode?> showCountryCodePicker(BuildContext context) {
  return showModalBottomSheet<CountryCode>(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    builder:            (_) => const _CountryPickerSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {

  final TextEditingController _searchCtrl = TextEditingController();
  Timer?  _debounce;
  String  _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<CountryCode> get _filtered {
    if (_query.trim().isEmpty) return _kCountries;
    final q = _query.trim().toLowerCase();
    return _kCountries.where((c) =>
      c.name.toLowerCase().contains(q) ||
      c.code.toLowerCase().contains(q) ||
      c.dialCode.contains(q)
    ).toList();
  }

  bool get _isFiltered => _query.trim().isNotEmpty;

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.50,
      maxChildSize:     0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXxl),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.spacingSm),
            const SheetHandle(),
            const SizedBox(height: AppConstants.spacingMd),

            // ── Title + close ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        context.tr('auth.phone'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SheetCloseButton(
                    semanticsLabel: context.tr('common.close'),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ── Search bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLg,
              ),
              child: Container(
                height: AppConstants.searchBarHeight,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurface
                      : AppTheme.lightSurfaceVariant,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: AppConstants.spacingMd),
                    Icon(
                      AppIcons.search,
                      size:  AppConstants.iconSizeSm,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged:  _onSearch,
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
                    if (_query.isNotEmpty)
                      IconButton(
                        icon:  const Icon(AppIcons.close, size: 16),
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingSm),

            // ── Country list ───────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _EmptySearch(isDark: isDark)
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.paddingLg,
                        0,
                        AppConstants.paddingLg,
                        AppConstants.paddingLg,
                      ),
                      // When not filtered: add a divider after DZ (index 0).
                      // When filtered: just a small gap between items.
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) {
                        if (!_isFiltered && index == 0) {
                          return Divider(
                            height:    20,
                            thickness: 0.5,
                            color: isDark
                                ? AppTheme.darkBorder
                                : AppTheme.lightBorder,
                          );
                        }
                        return const SizedBox(height: 4);
                      },
                      itemBuilder: (_, index) => _CountryTile(
                        country: filtered[index],
                        isDark:  isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context, filtered[index]);
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

// ─────────────────────────────────────────────────────────────────────────────
// Country tile
// ─────────────────────────────────────────────────────────────────────────────

class _CountryTile extends StatelessWidget {
  final CountryCode  country;
  final bool         isDark;
  final VoidCallback onTap;

  const _CountryTile({
    required this.country,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  '${country.name} ${country.dialCode}',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: AppConstants.tileHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMd,
            ),
            child: Row(
              children: [
                // Flag emoji — rendered at 22dp to match emojiIconSize token
                Text(
                  country.flag,
                  style: const TextStyle(fontSize: AppConstants.emojiIconSize),
                ),
                const SizedBox(width: AppConstants.spacingMd),

                // Country name
                Expanded(
                  child: Text(
                    country.name,
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeMd,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                ),

                // Dial code
                Text(
                  country.dialCode,
                  style: TextStyle(
                    fontSize:   AppConstants.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty search state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  final bool isDark;
  const _EmptySearch({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Text(
          context.tr('common.error'),
          style: TextStyle(
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
        ),
      ),
    );
  }
}
