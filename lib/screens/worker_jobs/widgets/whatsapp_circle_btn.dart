// lib/screens/worker_jobs/widgets/whatsapp_circle_btn.dart
//
// MERGED FROM:
//   - _WhatsAppCircleBtn  (job_detail_fab_row.dart)  — 46×46, has glow shadow
//   - _WhatsAppIconBtn    (job_action_buttons.dart)  — 40×40, no shadow
//
// REASON: Near-identical classes with identical logic (launchWhatsApp, _busy
//         state, error SnackBar, WhatsAppIcon). Only differences were size
//         (46 vs 40) and presence of a boxShadow. Unified via [size] parameter.
//
// FIX: Both files hardcoded Color(0xFF1B2B1B) for the dark-mode background.
//      AppTheme.whatsAppDarkSurface = Color(0xFF1B2B1B) exists for exactly
//      this purpose — now used here.

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/localization.dart';
import '../../../utils/whatsapp_launcher.dart'; // kWhatsAppGreen + WhatsAppIcon

class WhatsAppCircleBtn extends StatefulWidget {
  final String phone;
  final bool   isDark;
  final bool   disabled;
  final String label;

  /// Diameter of the circle button.
  /// Use 46 for the FAB row (job_detail_fab_row), 40 for the inline row
  /// (job_action_buttons).
  final double size;

  const WhatsAppCircleBtn({
    super.key,
    required this.phone,
    required this.isDark,
    this.disabled = false,
    required this.label,
    this.size = 46,
  });

  @override
  State<WhatsAppCircleBtn> createState() => _WhatsAppCircleBtnState();
}

class _WhatsAppCircleBtnState extends State<WhatsAppCircleBtn> {
  bool _busy = false;

  Future<void> _launch() async {
    if (_busy || widget.disabled) return;
    setState(() => _busy = true);
    try {
      final msg = context.tr('whatsapp.contact_message');
      final ok  = await launchWhatsApp(phone: widget.phone, message: msg);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text(context.tr('whatsapp.open_failed')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || _busy;

    // FIX: replaced hardcoded Color(0xFF1B2B1B) with AppTheme.whatsAppDarkSurface
    final bgColor = widget.isDark
        ? AppTheme.whatsAppDarkSurface
        : Colors.white;

    // Glow shadow only on larger (46dp) variant — matches original _WhatsAppCircleBtn.
    final shadow = widget.size >= 46
        ? [
            BoxShadow(
              color:      kWhatsAppGreen.withOpacity(0.15),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ]
        : null;

    return Semantics(
      button: true,
      label:  widget.label,
      child: GestureDetector(
        onTap: isDisabled ? null : _launch,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity:  isDisabled ? 0.45 : 1.0,
          child: Container(
            width:  widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color:     bgColor,
              shape:     BoxShape.circle,
              border:    Border.all(
                color: kWhatsAppGreen.withOpacity(0.55),
                width: 1.2,
              ),
              boxShadow: shadow,
            ),
            child: _busy
                ? Padding(
                    padding: EdgeInsets.all(widget.size * 0.22),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color:       kWhatsAppGreen,
                    ),
                  )
                : Center(
                    child: WhatsAppIcon(size: widget.size * 0.52),
                  ),
          ),
        ),
      ),
    );
  }
}
