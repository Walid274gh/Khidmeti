// lib/screens/worker_jobs/widgets/job_action_buttons.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'job_icon_btn.dart';
import 'job_text_btn.dart';
import 'job_primary_btn.dart';
import 'whatsapp_circle_btn.dart'; // REPLACED: inline _WhatsAppIconBtn

// CHANGES:
//   • _WhatsAppIconBtn removed — replaced by shared WhatsAppCircleBtn
//     (whatsapp_circle_btn.dart) with size: 40
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
        // REPLACED: inline _WhatsAppIconBtn → shared WhatsAppCircleBtn
        WhatsAppCircleBtn(
          phone:    job.userPhone,
          isDark:   isDark,
          disabled: isLoading,
          label:    context.tr('worker_jobs.chat_with_client'),
          size:     40, // inline-row variant: smaller, no glow
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
