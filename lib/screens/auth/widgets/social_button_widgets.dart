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
                ? AppTheme.darkBorder
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
                ? AppTheme.darkBorder
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
// FIX [Col-OPAC]: darkSurface.withOpacity(0.5) → AppTheme.darkSurfaceHalf
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
    final borderColor = isDisabled
        ? AppTheme.disabledBorder
        : (isDark
            ? AppTheme.darkSocialBorder
            : AppTheme.lightBorder);

    return Semantics(
      button: true,
      label:  semanticLabel,
      child: SizedBox(
        width:  AppConstants.socialButtonSize,
        height: AppConstants.socialButtonSize,
        child: Material(
          // FIX [Col-OPAC]: was darkSurface.withOpacity(0.5) — replaced with
          // pre-baked AppTheme.darkSurfaceHalf token (Color(0x80141028)).
          color: isDark
              ? AppTheme.darkSurfaceHalf
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
                      width:  AppConstants.socialSpinnerSize,
                      height: AppConstants.socialSpinnerSize,
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
// FIX [Col-OPAC]: Colors.white / Colors.black → AppTheme.darkText / lightText
// These are semantic theme tokens — they adapt correctly if the palette ever
// changes, whereas Colors.white / Colors.black are hardcoded absolutes.
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
        isDark ? AppTheme.darkText : AppTheme.lightText,
        BlendMode.srcIn,
      ),
    );
  }
}
