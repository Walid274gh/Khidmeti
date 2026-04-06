// lib/screens/auth/widgets/profession_picker_sheet.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/sheet_handle.dart';
import 'register_service_picker.dart';

class ProfessionPickerSheet extends StatefulWidget {
  final bool isDark;

  const ProfessionPickerSheet({super.key, required this.isDark});

  @override
  State<ProfessionPickerSheet> createState() => _ProfessionPickerSheetState();
}

class _ProfessionPickerSheetState extends State<ProfessionPickerSheet> {
  String? _selected;

  static final List<String> _professions =
      kRegisterServices.map((s) => s['key'] as String).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Container(
      margin: EdgeInsets.only(
        top:    MediaQuery.of(context).size.height * .15,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXxl),
        ),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 0.5,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIX [Dim-RAW]: was EdgeInsets.only(top: 12, bottom: 4) — replaced
            // with token-backed values: spacingChipGap (12dp) and spacingXs (4dp).
            Padding(
              padding: const EdgeInsets.only(
                top:    AppConstants.spacingChipGap,
                bottom: AppConstants.spacingXs,
              ),
              child: SheetHandle(isDark: isDark),
            ),
            // FIX [Dim-RAW]: was EdgeInsets.fromLTRB(paddingLg, 12, paddingLg, 8) —
            // the inner 12 → spacingChipGap; 8 → spacingSm (already a token).
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingLg,
                AppConstants.spacingChipGap,
                AppConstants.paddingLg,
                AppConstants.spacingSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      context.tr('register.service_label'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          ),
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingSm),
                  Text(
                    context.tr('register.service_picker_subtitle'),
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeSm,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLg,
                  vertical:   AppConstants.paddingSm,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:   2,
                  childAspectRatio: 3.2,
                  crossAxisSpacing: AppConstants.sectionCardGap,
                  mainAxisSpacing:  AppConstants.sectionCardGap,
                ),
                itemCount: _professions.length,
                itemBuilder: (ctx, i) {
                  final prof       = _professions[i];
                  final isSelected = _selected == prof;
                  return Semantics(
                    button:   true,
                    selected: isSelected,
                    label:    context.tr('services.$prof'),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = prof),
                      child: AnimatedContainer(
                        duration:  AppConstants.animDurationMicro,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          // FIX [Col-OPAC]: was accent.withOpacity(0.15) —
                          // replaced with pre-baked AppTheme.accentSelectedFill
                          // (accent #4F46E5 @ 15%, alpha 0x26).
                          color: isSelected
                              ? AppTheme.accentSelectedFill
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMd),
                          border: Border.all(
                            color: isSelected
                                ? accent
                                : (isDark
                                    ? AppTheme.sheetHandleDark
                                    : AppTheme.lightBorder),
                          ),
                        ),
                        child: Text(
                          context.tr('services.$prof'),
                          style: TextStyle(
                            fontSize:   AppConstants.fontSizeSm,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? accent
                                : (isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLg),
              child: SizedBox(
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () {
                          if (!mounted) return;
                          Navigator.of(context).pop(_selected);
                        },
                  child: Text(context.tr('common.confirm')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
