// lib/screens/auth/widgets/social_button_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../utils/app_social_assets.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// SOCIAL DIVIDER
// ============================================================================

class SocialDivider extends StatelessWidget {
  final bool isDark;
  const SocialDivider({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color:  isDark
                ? AppTheme.sheetHandleDark
                : AppTheme.lightBorder,
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMd),
          child: Text(
            context.tr('social.or_continue_with'),
            style: TextStyle(
              fontSize: AppConstants.fontSizeSm,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color:  isDark
                ? AppTheme.sheetHandleDark
                : AppTheme.lightBorder,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CIRCULAR SOCIAL BUTTON
// FIX (UI Quality): logo SizedBox changed from 22×22 to 24×24.
// 22dp is off the 8dp grid (16 / 20 / 24 / 32). 24dp is the standard icon
// size in AppConstants.iconSizeMd and aligns with the rest of the app.
//
// FIX [SVG]: border colour was Colors.white.withOpacity(0.18) — replaced
// with pre-baked AppTheme.darkSocialBorder token (white @ 18%).
// ============================================================================

class CircularSocialButton extends StatelessWidget {
  final bool          isDark;
  final String        semanticLabel;
  final bool          isLoading;
  final bool          isDisabled;
  final Widget        logo;
  final VoidCallback? onPressed;

  const CircularSocialButton({
    super.key,
    required this.isDark,
    required this.semanticLabel,
    required this.isLoading,
    required this.isDisabled,
    required this.logo,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // FIX [SVG]: was Colors.white.withOpacity(0.18) — now uses
    // AppTheme.darkSocialBorder (pre-baked const token, white @ 18%).
    final borderColor = isDisabled
        ? AppTheme.disabledBorder
        : (isDark
            ? AppTheme.darkSocialBorder
            : AppTheme.lightBorder);

    return Semantics(
      button: true,
      label:  semanticLabel,
      child: SizedBox(
        width:  52,
        height: 52,
        child: Material(
          color: isDark
              ? AppTheme.darkSurface.withOpacity(0.5)
              : AppTheme.lightSurface,
          shape: CircleBorder(
            side: BorderSide(color: borderColor, width: 1),
          ),
          child: InkWell(
            onTap:        isDisabled ? null : onPressed,
            customBorder: const CircleBorder(),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width:  18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark
                            ? AppTheme.darkAccent
                            : AppTheme.lightAccent,
                      ),
                    )
                  : SizedBox(
                      width:  AppConstants.iconSizeMd,
                      height: AppConstants.iconSizeMd,
                      child: logo,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GOOGLE LOGO
// FIX [SVG]: CustomPainter replaced with SvgPicture.asset.
// Requires:
//   • flutter_svg: ^2.0.10+1 in pubspec.yaml
//   • assets/images/social/google.svg (official Google G logo)
//   • assets/images/social/ declared in pubspec.yaml flutter.assets block
// ============================================================================

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppSocialAssets.google,
      fit: BoxFit.contain,
    );
  }
}

// ============================================================================
// FACEBOOK LOGO
// FIX [SVG]: CustomPainter replaced with SvgPicture.asset.
// Requires:
//   • flutter_svg: ^2.0.10+1 in pubspec.yaml
//   • assets/images/social/facebook.svg (official Facebook f logo)
//   • assets/images/social/ declared in pubspec.yaml flutter.assets block
// ============================================================================

class FacebookLogo extends StatelessWidget {
  const FacebookLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppSocialAssets.facebook,
      fit: BoxFit.contain,
    );
  }
}

// ============================================================================
// APPLE LOGO
// FIX [SVG]: CustomPainter replaced with SvgPicture.asset.
// The monochrome Apple SVG must be colourised per theme at runtime using
// colorFilter — the official logo uses a single path, so a ColorFilter
// is the correct approach rather than separate dark/light SVG files.
//
// Requires:
//   • flutter_svg: ^2.0.10+1 in pubspec.yaml
//   • assets/images/social/apple.svg (official Apple logo, monochrome)
//   • assets/images/social/ declared in pubspec.yaml flutter.assets block
// ============================================================================

class AppleLogo extends StatelessWidget {
  final bool isDark;
  const AppleLogo({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppSocialAssets.apple,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        isDark ? Colors.white : Colors.black,
        BlendMode.srcIn,
      ),
    );
  }
}
