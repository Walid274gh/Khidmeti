// lib/screens/onboarding/widgets/language_picker_pill.dart
//
// Tappable pill showing current language flag + code.
// Opens a BottomSheet with three language options (fr / en / ar).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/core_providers.dart';
import '../../../services/language_service.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/sheet_handle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Language option data
// ─────────────────────────────────────────────────────────────────────────────

class _LangOption {
  final String code;
  final String flag;
  final String label;

  const _LangOption({
    required this.code,
    required this.flag,
    required this.label,
  });
}

const List<_LangOption> _kLangs = [
  _LangOption(code: 'fr', flag: '🇫🇷', label: 'Français'),
  _LangOption(code: 'ar', flag: '🇩🇿', label: 'العربية'),
  _LangOption(code: 'en', flag: '🇬🇧', label: 'English'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Pill widget
// ─────────────────────────────────────────────────────────────────────────────

class LanguagePickerPill extends ConsumerWidget {
  const LanguagePickerPill({super.key});

  String _flagForCode(String code) {
    return _kLangs.firstWhere(
      (l) => l.code == code,
      orElse: () => _kLangs.first,
    ).flag;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = ref.watch(currentLanguageCodeProvider);
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final accent   = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Semantics(
      button: true,
      label:  'Change language, current: $langCode',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showSheet(context, ref, langCode, isDark);
        },
        child: Container(
          height:  AppConstants.buttonHeightMd,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkSurface
                : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _flagForCode(langCode),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                langCode.toUpperCase(),
                style: TextStyle(
                  fontSize:   AppConstants.fontSizeSm,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size:  16,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSheet(
    BuildContext context,
    WidgetRef    ref,
    String       current,
    bool         isDark,
  ) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: false,
      backgroundColor:    Colors.transparent,
      builder: (_) => _LanguageSheet(
        current: current,
        isDark:  isDark,
        onSelect: (code) async {
          Navigator.pop(context);
          await ref
              .read(languageServiceProvider)
              .changeLanguage(code);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language selection sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageSheet extends StatelessWidget {
  final String             current;
  final bool               isDark;
  final ValueChanged<String> onSelect;

  const _LanguageSheet({
    required this.current,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingLg,
        AppConstants.paddingMd,
        AppConstants.paddingLg,
        MediaQuery.of(context).padding.bottom + AppConstants.paddingLg,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHandle(isDark: isDark),
          const SizedBox(height: AppConstants.spacingLg),

          Semantics(
            header: true,
            child: Text(
              context.tr('settings.language'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacingMd),

          ...(_kLangs.map((lang) {
            final isSelected = lang.code == current;
            return Semantics(
              button:   true,
              selected: isSelected,
              label:    lang.label,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(lang.code);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
                  height: AppConstants.tileHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMd,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentSelectedFill
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? accent
                          : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      width: isSelected
                          ? AppConstants.borderWidthSelected
                          : AppConstants.borderWidthDefault,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        lang.flag,
                        style: const TextStyle(fontSize: AppConstants.iconSizeSm),
                      ),
                      const SizedBox(width: AppConstants.spacingMd),
                      Expanded(
                        child: Text(
                          lang.label,
                          style: TextStyle(
                            fontSize:   AppConstants.fontSizeMd,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: accent,
                          size:  AppConstants.iconSizeSm,
                        ),
                    ],
                  ),
                ),
              ),
            );
          })),
        ],
      ),
    );
  }
}
