// lib/screens/worker_jobs/widgets/job_detail_fab_row.dart

import 'package:flutter/material.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import 'job_accept_decline_row.dart';
import 'job_complete_btn.dart';
import 'job_completed_badge.dart';
import 'job_loading_btn.dart';
import 'whatsapp_circle_btn.dart'; // REPLACED: inline _WhatsAppCircleBtn

// ============================================================================
// JOB DETAIL FAB ROW — flat surface, no BackdropFilter
//
// CHANGES:
//   • _WhatsAppCircleBtn extracted to WhatsAppCircleBtn (whatsapp_circle_btn.dart)
//   • context: removed from JobAcceptDeclineRow, JobCompleteBtn, JobCompletedBadge
//     (those widgets now obtain context from their own build() parameter)
// ============================================================================

class JobDetailFabRow extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool         isLoading;
  final bool         isDark;
  final Color        accentColor;
  final String       userPhone;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onComplete;

  const JobDetailFabRow({
    super.key,
    required this.job,
    required this.isLoading,
    required this.isDark,
    required this.accentColor,
    required this.userPhone,
    required this.onAccept,
    required this.onDecline,
    required this.onComplete,
  });

  bool get _isTerminal =>
      job.status == ServiceStatus.completed ||
      job.status == ServiceStatus.cancelled ||
      job.status == ServiceStatus.declined;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingMd,
        0,
        AppConstants.paddingMd,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // ── WhatsApp circle (always visible) ─────────────────────
            // REPLACED: inline _WhatsAppCircleBtn → shared WhatsAppCircleBtn
            WhatsAppCircleBtn(
              phone:    userPhone,
              isDark:   isDark,
              label:    context.tr('worker_jobs.chat_with_client'),
              size:     46, // FAB-row variant: larger with glow
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // ── Primary CTA ───────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isTerminal
                    ? JobCompletedBadge(isDark: isDark)         // context: removed
                    : isLoading
                        ? JobLoadingBtn(accentColor: accentColor)
                        : job.status == ServiceStatus.pending
                            ? JobAcceptDeclineRow(               // context: removed
                                onAccept:  onAccept,
                                onDecline: onDecline,
                              )
                            : (job.status == ServiceStatus.accepted ||
                                    job.status == ServiceStatus.inProgress)
                                ? JobCompleteBtn(               // context: removed
                                    accentColor: accentColor,
                                    onTap:       onComplete,
                                  )
                                : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
