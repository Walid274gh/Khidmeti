// lib/screens/worker_jobs/widgets/job_action_buttons.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/whatsapp_launcher.dart';
import 'job_icon_btn.dart';
import 'job_text_btn.dart';
import 'job_primary_btn.dart';

class JobActionButtons extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool      isLoading;
  final bool      isSuccess;
  final bool      isDark;
  final Color     accentColor;
  final VoidCallback onAccept;
  final VoidCallback onComplete;
  final VoidCallback onDecline;
  final VoidCallback onLocation;
  final VoidCallback? onMedia;

  const JobActionButtons({
    super.key,
    required this.job,
    required this.isLoading,
    required this.isSuccess,
    required this.isDark,
    required this.accentColor,
    required this.onAccept,
    required this.onComplete,
    required this.onDecline,
    required this.onLocation,
    required this.onMedia,
  });

  bool get _isCompleted =>
      job.status == ServiceStatus.completed ||
      job.status == ServiceStatus.cancelled ||
      job.status == ServiceStatus.declined;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── WhatsApp contact button ───────────────────────────────────
        _WhatsAppIconBtn(
          phone:     job.userPhone,
          isDark:    isDark,
          disabled:  isLoading,
          label:     context.tr('worker_jobs.chat_with_client'),
        ),
        const SizedBox(width: AppConstants.spacingXs),

        // ── Location ──────────────────────────────────────────────────
        JobIconBtn(
          icon:   AppIcons.location,
          label:  context.tr('worker_jobs.view_location'),
          color:  AppTheme.iconViolet,
          isDark: isDark,
          onTap:  isLoading ? null : onLocation,
        ),

        // ── Media (optional) ──────────────────────────────────────────
        if (onMedia != null) ...[
          const SizedBox(width: AppConstants.spacingXs),
          JobIconBtn(
            icon:   Icons.perm_media_rounded,
            label:  context.tr('worker_jobs.view_media'),
            color:  AppTheme.darkAccent,
            isDark: isDark,
            onTap:  isLoading ? null : onMedia,
          ),
        ],

        const Spacer(),

        // ── Status-based primary actions ──────────────────────────────
        if (!_isCompleted && !isSuccess) ...[
          if (job.status == ServiceStatus.pending) ...[
            JobTextBtn(
              label: context.tr('worker_jobs.decline_job'),
              color: AppTheme.signOutRed,
              onTap: isLoading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onDecline();
                    },
            ),
            const SizedBox(width: AppConstants.spacingXs),
            JobPrimaryBtn(
              label: context.tr('worker_jobs.accept_job'),
              icon:  Icons.check_rounded,
              color: AppTheme.onlineGreen,
              onTap: isLoading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onAccept();
                    },
            ),
          ] else if (job.status == ServiceStatus.accepted ||
              job.status == ServiceStatus.inProgress) ...[
            JobPrimaryBtn(
              label: context.tr('worker_jobs.complete_job'),
              icon:  Icons.done_all_rounded,
              color: accentColor,
              onTap: isLoading ? null : onComplete,
            ),
          ],
        ],
      ],
    );
  }
}

// ============================================================================
// _WhatsAppIconBtn
// Matches the size/shape of JobIconBtn but uses the WhatsApp icon.
// White background so the coloured PNG is clearly visible.
// ============================================================================

class _WhatsAppIconBtn extends StatefulWidget {
  final String phone;
  final bool   isDark;
  final bool   disabled;
  final String label;

  const _WhatsAppIconBtn({
    required this.phone,
    required this.isDark,
    required this.disabled,
    required this.label,
  });

  @override
  State<_WhatsAppIconBtn> createState() => _WhatsAppIconBtnState();
}

class _WhatsAppIconBtnState extends State<_WhatsAppIconBtn> {
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

    return Semantics(
      button: true,
      label:  widget.label,
      child: GestureDetector(
        onTap: isDisabled ? null : _launch,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity:  isDisabled ? 0.45 : 1.0,
          child: Container(
            width:  40,
            height: 40,
            decoration: BoxDecoration(
              color:  widget.isDark
                  ? const Color(0xFF1B2B1B)
                  : Colors.white,
              shape:  BoxShape.circle,
              border: Border.all(
                color: kWhatsAppGreen.withOpacity(0.50),
                width: 1.2,
              ),
            ),
            child: _busy
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:       kWhatsAppGreen,
                    ),
                  )
                : Center(child: WhatsAppIcon(size: 20)),
          ),
        ),
      ),
    );
  }
}
