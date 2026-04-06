// lib/screens/auth/widgets/profession_picker_sheet.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/sheet_handle.dart';
import 'auth_submit_button.dart';
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
            Padding(
              padding: const EdgeInsets.only(
                top:    AppConstants.spacingChipGap,
                bottom: AppConstants.spacingXs,
              ),
              child: SheetHandle(isDark: isDark),
            ),
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
                          color: isSelected
                              ? AppTheme.accentSelectedFill
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMd),
                          border: Border.all(
                            // FIX [Col-SEM]: was AppTheme.sheetHandleDark (a
                            // drag-handle token, semantic mismatch) — replaced
                            // with AppTheme.darkBorder, the correct divider token.
                            color: isSelected
                                ? accent
                                : (isDark
                                    ? AppTheme.darkBorder
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
            // FIX [BTN-SPLIT]: ElevatedButton confirm CTA → AuthSubmitButton
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLg),
              child: AuthSubmitButton(
                isLoading: false,
                isDark:    isDark,
                onPressed: _selected == null
                    ? null
                    : () {
                        if (!mounted) return;
                        Navigator.of(context).pop(_selected);
                      },
                labelKey: 'common.confirm',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
