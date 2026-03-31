// lib/screens/auth/widgets/profession_picker_sheet.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
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
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width:  AppConstants.sheetHandleWidth,
                height: AppConstants.sheetHandleHeight,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingLg, 12, AppConstants.paddingLg, 8,
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
                        duration:  const Duration(milliseconds: 200),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accent.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMd),
                          border: Border.all(
                            color: isSelected
                                ? accent
                                : (isDark
                                    ? Colors.white.withOpacity(0.15)
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
                      // FIX (QA P0): added mounted check before pop — the
                      // sheet can be dismissed by a system swipe gesture
                      // simultaneously with a tap on Confirm, leaving the
                      // context unmounted.
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
