// lib/widgets/whatsapp_button.dart

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Renders the WhatsApp icon from the project asset.
///
/// KEY RULE: Never pass a `color:` tint to the image — the PNG already
/// contains its own green/white colours. Applying any tint (especially
/// `Colors.white`) will turn the entire image solid white.
///
/// Falls back to [_WhatsAppFallback] when the asset is missing.
class WhatsAppIcon extends StatelessWidget {
  final double size;

  const WhatsAppIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  size,
      height: size,
      child: Image.asset(
        'assets/images/whatsapp.png',
        width:  size,
        height: size,
        // NO color parameter — would tint the whole image.
        fit:    BoxFit.contain,
        errorBuilder: (_, __, ___) => _WhatsAppFallback(size: size),
      ),
    );
  }
}

/// Fallback drawn with Flutter widgets — shown when the PNG asset has not
/// yet been added to the project.
class _WhatsAppFallback extends StatelessWidget {
  final double size;
  const _WhatsAppFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        // FIX [WARN]: was hardcoded `Color(0xFF25D366)`.
        // Now uses AppTheme.whatsAppGreen token.
        color:        AppTheme.whatsAppGreen,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Center(
        child: Icon(
          Icons.phone_rounded,
          color: Colors.white,
          size:  size * 0.60,
        ),
      ),
    );
  }
}

/// [ButtonStyle] for an outlined WhatsApp CTA button.
/// White background + green border/text — works in both light and dark mode.
ButtonStyle whatsAppOutlinedStyle({required bool isDark}) {
  return OutlinedButton.styleFrom(
    backgroundColor: isDark ? const Color(0xFF1E2A1E) : Colors.white,
    // FIX [WARN]: was hardcoded `Color(0xFF25D366)`.
    foregroundColor: AppTheme.whatsAppGreen,
    side: BorderSide(color: AppTheme.whatsAppGreen.withOpacity(0.6), width: 1.2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  );
}

/// [ButtonStyle] for a filled WhatsApp CTA button.
/// Uses the darker WhatsApp teal so icon contrast is maintained.
ButtonStyle whatsAppFilledStyle() {
  return ElevatedButton.styleFrom(
    // FIX [WARN]: was hardcoded `Color(0xFF128C7E)`.
    // Now uses AppTheme.whatsAppDark token.
    backgroundColor: AppTheme.whatsAppDark,
    foregroundColor: Colors.white,
    elevation:       0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
