// lib/screens/service_request/widgets/form_bottom_nav.dart
//
// [C2] FIX: Container height: 52 (Next/Submit CTA) →
//      height: AppConstants.buttonHeightMd (48dp).
// [W1] FIX: Back button width: 52, height: 52 →
//      width: AppConstants.backButtonSize, height: AppConstants.backButtonSize (48dp).
// [W5] FIX: spinner SizedBox(width: 18, height: 18) →
//      SizedBox(width: AppConstants.spinnerSizeLg, height: AppConstants.spinnerSizeLg) (20dp).
// [W4] FIX: color: Colors.black (spinner + text) → AppTheme.lightText.

import 'package:flutter/material.dart';

import '../../../providers/service_request_form_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// FORM BOTTOM NAV
// Back button (steps > 0) + full-width Next / Submit CTA.
// ============================================================================

class FormBottomNav extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final int currentStep;
  final ServiceRequestFormState state;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const FormBottomNav({
    super.key,
    required this.isDark,
    required this.accent,
    required this.currentStep,
    required this.state,
    required this.onBack,
    required this.onNext,
  });

  String _nextLabel(BuildContext context) {
    if (currentStep < 2) return context.tr('common.next');
    return switch (state.submitStatus) {
      SubmitStatus.uploading => context.tr('request_form.uploading_media'),
      SubmitStatus.submitting => context.tr('request_form.submitting'),
      _ => context.tr('request_form.submit_button'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == 2;
    final label = _nextLabel(context);
    final isEnabled = onNext != null && !state.isSubmitting;

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkBackground : AppTheme.lightBackground)
            .withOpacity(0.97),
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          ),
        ),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppConstants.paddingMd,
        AppConstants.paddingSm,
        AppConstants.paddingMd,
        AppConstants.paddingSm + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Semantics(
              button: true,
              label: context.tr('common.back'),
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  // [W1] FIX: 52dp → backButtonSize (48dp)
                  width:  AppConstants.backButtonSize,
                  height: AppConstants.backButtonSize,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.06),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.08),
                    ),
                  ),
                  child: Icon(
                    AppIcons.back,
                    size: 20,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
          ],
          Expanded(
            child: Semantics(
              button: true,
              label: label,
              enabled: isEnabled,
              child: GestureDetector(
                onTap: isEnabled ? onNext : null,
                child: AnimatedOpacity(
                  opacity: isEnabled ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    // [C2] FIX: height: 52 → buttonHeightMd (48dp)
                    height: AppConstants.buttonHeightMd,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMd),
                      boxShadow: isEnabled
                          ? [
                              BoxShadow(
                                color: accent.withOpacity(0.30),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state.isSubmitting) ...[
                          // [W5] FIX: 18dp → spinnerSizeLg (20dp)
                          SizedBox(
                            width:  AppConstants.spinnerSizeLg,
                            height: AppConstants.spinnerSizeLg,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              // [W4] FIX: Colors.black → AppTheme.lightText
                              color: AppTheme.lightText,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingSm),
                        ],
                        Text(
                          label,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    // [W4] FIX: Colors.black → AppTheme.lightText
                                    color: AppTheme.lightText,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        if (!isLast && !state.isSubmitting) ...[
                          const SizedBox(width: AppConstants.spacingXs),
                          // [W4] FIX: Colors.black → AppTheme.lightText
                          Icon(Icons.arrow_forward_rounded,
                              size: 18, color: AppTheme.lightText),
                        ],
                      ],
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
