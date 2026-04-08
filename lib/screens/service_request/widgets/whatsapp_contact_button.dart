// lib/screens/service_request/widgets/whatsapp_contact_button.dart
//
// [C2] FIX: height: 50 → AppConstants.buttonHeightMd (48dp).
// [W5] FIX: const SizedBox(width: 10) → const SizedBox(width: AppConstants.spacingSm) (8dp).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../providers/core_providers.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/whatsapp_launcher.dart';

// ============================================================================
// WHATSAPP CONTACT BUTTON
// ============================================================================

class WhatsAppContactButton extends ConsumerStatefulWidget {
  final ServiceRequestEnhancedModel request;
  final bool                        isDark;

  const WhatsAppContactButton({
    super.key,
    required this.request,
    required this.isDark,
  });

  @override
  ConsumerState<WhatsAppContactButton> createState() =>
      _WhatsAppContactButtonState();
}

class _WhatsAppContactButtonState
    extends ConsumerState<WhatsAppContactButton> {
  bool _launching = false;

  Future<void> _launch(String phone) async {
    if (_launching) return;
    setState(() => _launching = true);
    try {
      final msg = context.tr('whatsapp.contact_message');
      final ok  = await launchWhatsApp(phone: phone, message: msg);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text(context.tr('whatsapp.open_failed')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  Widget _buildButton({
    required BuildContext context,
    required bool         isDark,
    required String?      phone,
    required bool         isLoading,
  }) {
    return Semantics(
      button:  true,
      label:   context.tr('tracking.contact_worker'),
      enabled: !isLoading && phone != null,
      child: SizedBox(
        width:  double.infinity,
        // [C2] FIX: height: 50 → buttonHeightMd (48dp)
        height: AppConstants.buttonHeightMd,
        child: ElevatedButton(
          onPressed:
              (isLoading || phone == null) ? null : () => _launch(phone),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
                ? AppTheme.whatsAppDarkSurface
                : Colors.white,
            foregroundColor: kWhatsAppGreen,
            disabledBackgroundColor: isDark
                ? AppTheme.whatsAppDarkSurface.withOpacity(0.5)
                : Colors.white.withOpacity(0.5),
            elevation: 0,
            side: BorderSide(
                color: kWhatsAppGreen.withOpacity(0.55), width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width:  AppConstants.spinnerSizeLg,
                  height: AppConstants.spinnerSizeLg,
                  child:  CircularProgressIndicator(
                      strokeWidth: 2, color: kWhatsAppGreen),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WhatsAppIcon(size: 22),
                    // [W5] FIX: SizedBox(width: 10) → spacingSm (8dp)
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      context.tr('tracking.contact_worker'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color:      kWhatsAppGreen,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workerId    = widget.request.workerId!;
    final workerAsync = ref.watch(workerProfileProvider(workerId));

    return workerAsync.when(
      loading: () => _buildButton(
          context: context,
          isDark:  widget.isDark,
          phone:   null,
          isLoading: true),
      error: (_, __) => const SizedBox.shrink(),
      data: (worker) {
        final phone = worker?.phoneNumber ?? '';
        if (phone.trim().isEmpty) return const SizedBox.shrink();
        return _buildButton(
          context:   context,
          isDark:    widget.isDark,
          phone:     phone,
          isLoading: _launching,
        );
      },
    );
  }
}
