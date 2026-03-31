// lib/screens/auth/widgets/social_button_widgets.dart

import 'package:flutter/material.dart';

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
                ? Colors.white.withOpacity(0.12)
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
                ? Colors.white.withOpacity(0.12)
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
            ? Colors.white.withOpacity(0.18)
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
                  // FIX: 22×22 → 24×24 (AppConstants.iconSizeMd — on 8dp grid)
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
    return CustomPaint(painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static final Paint _blue   = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
  static final Paint _green  = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;
  static final Paint _yellow = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
  static final Paint _red    = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    canvas.drawPath(
      Path()
        ..moveTo(s * .898, s * .510)
        ..cubicTo(s * .898, s * .474, s * .895, s * .439, s * .888, s * .406)
        ..lineTo(s * .500, s * .406)
        ..lineTo(s * .500, s * .579)
        ..lineTo(s * .724, s * .579)
        ..cubicTo(s * .714, s * .632, s * .685, s * .677, s * .638, s * .705)
        ..lineTo(s * .638, s * .821)
        ..cubicTo(s * .776, s * .751, s * .898, s * .645, s * .898, s * .510)
        ..close(),
      _blue,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * .500, s * .917)
        ..cubicTo(s * .625, s * .917, s * .729, s * .875, s * .804, s * .800)
        ..lineTo(s * .638, s * .684)
        ..cubicTo(s * .596, s * .711, s * .553, s * .729, s * .500, s * .729)
        ..cubicTo(s * .381, s * .729, s * .276, s * .653, s * .236, s * .549)
        ..lineTo(s * .064, s * .549)
        ..lineTo(s * .064, s * .666)
        ..cubicTo(s * .139, s * .807, s * .308, s * .917, s * .500, s * .917)
        ..close(),
      _green,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * .236, s * .549)
        ..cubicTo(s * .224, s * .511, s * .219, s * .473, s * .219, s * .437)
        ..cubicTo(s * .219, s * .401, s * .224, s * .363, s * .236, s * .325)
        ..lineTo(s * .236, s * .208)
        ..lineTo(s * .064, s * .208)
        ..cubicTo(s * .024, s * .285, 0, s * .367, 0, s * .437)
        ..cubicTo(0, s * .507, s * .024, s * .589, s * .064, s * .666)
        ..close(),
      _yellow,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * .500, s * .146)
        ..cubicTo(s * .558, s * .146, s * .610, s * .166, s * .651, s * .205)
        ..lineTo(s * .778, s * .082)
        ..cubicTo(s * .700, s * .012, s * .601, 0, s * .500, 0)
        ..cubicTo(s * .308, 0, s * .139, s * .110, s * .064, s * .208)
        ..lineTo(s * .236, s * .325)
        ..cubicTo(s * .276, s * .221, s * .381, s * .146, s * .500, s * .146)
        ..close(),
      _red,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ============================================================================
// FACEBOOK LOGO
// ============================================================================

class FacebookLogo extends StatelessWidget {
  const FacebookLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FacebookLogoPainter());
  }
}

class _FacebookLogoPainter extends CustomPainter {
  static final Paint _bgPaint = Paint()
    ..color = const Color(0xFF1877F2)
    ..style = PaintingStyle.fill;
  static final Paint _fPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawCircle(Offset(s / 2, s / 2), s / 2, _bgPaint);
    canvas.drawPath(
      Path()
        ..moveTo(s * .583, s * .458)
        ..lineTo(s * .558, s * .458)
        ..lineTo(s * .558, s * .792)
        ..lineTo(s * .430, s * .792)
        ..lineTo(s * .430, s * .458)
        ..lineTo(s * .375, s * .458)
        ..lineTo(s * .375, s * .354)
        ..lineTo(s * .430, s * .354)
        ..lineTo(s * .430, s * .295)
        ..cubicTo(s * .430, s * .208, s * .468, s * .167, s * .573, s * .167)
        ..lineTo(s * .625, s * .167)
        ..lineTo(s * .625, s * .271)
        ..lineTo(s * .583, s * .271)
        ..cubicTo(s * .548, s * .271, s * .558, s * .288, s * .558, s * .312)
        ..lineTo(s * .558, s * .354)
        ..lineTo(s * .625, s * .354)
        ..lineTo(s * .600, s * .458)
        ..close(),
      _fPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ============================================================================
// APPLE LOGO
// ============================================================================

class AppleLogo extends StatelessWidget {
  final bool isDark;
  const AppleLogo({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AppleLogoPainter(isDark: isDark));
  }
}

class _AppleLogoPainter extends CustomPainter {
  final bool isDark;
  late final Paint _paint = Paint()
    ..color = isDark ? Colors.white : Colors.black
    ..style = PaintingStyle.fill;

  _AppleLogoPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawPath(
      Path()
        ..moveTo(s * .500, s * .180)
        ..cubicTo(s * .556, s * .180, s * .620, s * .145, s * .620, s * .145)
        ..cubicTo(s * .620, s * .200, s * .590, s * .240, s * .550, s * .260)
        ..cubicTo(s * .610, s * .260, s * .680, s * .220, s * .710, s * .180)
        ..cubicTo(s * .760, s * .240, s * .790, s * .320, s * .790, s * .420)
        ..cubicTo(s * .790, s * .600, s * .690, s * .790, s * .570, s * .830)
        ..cubicTo(s * .540, s * .840, s * .500, s * .840, s * .460, s * .830)
        ..cubicTo(s * .400, s * .810, s * .360, s * .810, s * .300, s * .830)
        ..cubicTo(s * .180, s * .790, s * .080, s * .600, s * .080, s * .420)
        ..cubicTo(s * .080, s * .260, s * .180, s * .180, s * .280, s * .180)
        ..cubicTo(s * .330, s * .180, s * .380, s * .200, s * .420, s * .200)
        ..cubicTo(s * .450, s * .200, s * .480, s * .180, s * .500, s * .180)
        ..close(),
      _paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AppleLogoPainter old) => old.isDark != isDark;
}
