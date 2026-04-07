// lib/screens/auth/register_header.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// REGISTER HEADER
// ============================================================================

class RegisterHeader extends StatelessWidget {
  final bool isDark;

  const RegisterHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // FIX (L10n+RTL P1): Icons.arrow_back_rounded is directional — in Arabic
    // (RTL) the back arrow must point right (forward in LTR), not left.
    // Directionality.of(context) reads the ambient TextDirection set by the
    // app's locale, so this adapts automatically at runtime.
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        // FIX [MANUAL]: raised touch target from AppConstants.buttonHeightSm
        // (44dp) to AppConstants.backButtonSize (48dp). The previous comment
        // "meets the 44dp minimum" was factually wrong for Material — the
        // Material Design minimum interactive touch target is 48dp. Apple HIG
        // allows 44dp, but 48dp satisfies both platforms simultaneously.
        Semantics(
          button: true,
          label:  context.tr('common.back'),
          child: GestureDetector(
            onTap: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.login),
            child: Container(
              width:  AppConstants.backButtonSize,
              height: AppConstants.backButtonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // FIX [C1/P1]: was Colors.white.withOpacity(0.08) /
                // Colors.black.withOpacity(0.06) — replaced with pre-baked
                // AppTheme.darkBackButtonFill / lightBackButtonFill tokens.
                color: isDark
                    ? AppTheme.darkBackButtonFill
                    : AppTheme.lightBackButtonFill,
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 0.5,
                ),
              ),
              child: Icon(
                isRTL
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_back_rounded,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                size:  AppConstants.iconSizeSm,
              ),
            ),
          ),
        ),

        SizedBox(height: AppConstants.spacingLg),

        Semantics(
          header: true,
          child: Text(
            context.tr('register.title'),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight:    FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
        ),

        SizedBox(height: AppConstants.spacingSm),

        Text(
          context.tr('register.subtitle'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
        ),
      ],
    );
  }
}
