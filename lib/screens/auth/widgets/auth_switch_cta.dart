// lib/screens/auth/widgets/auth_switch_cta.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// AUTH SWITCH CTA
// ============================================================================

class AuthSwitchCta extends StatelessWidget {
  final String promptKey;
  final String linkKey;
  final String route;
  final bool   isDark;

  const AuthSwitchCta({
    super.key,
    required this.promptKey,
    required this.linkKey,
    required this.route,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.tr(promptKey),
          style: TextStyle(
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
        ),
        // FIX [A11Y-DUP]: removed outer Semantics(button: true, label:) wrapper.
        // TextButton with a visible text child already exposes correct button
        // semantics to screen readers. The redundant wrapper caused double-
        // labelling, which harms TalkBack / VoiceOver users.
        TextButton(
          onPressed: () => context.go(route),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingSm),
          ),
          child: Text(
            context.tr(linkKey),
            style: TextStyle(
              color:      isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
