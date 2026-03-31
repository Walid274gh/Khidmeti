// lib/screens/worker_jobs/widgets/job_detail_fab_row.dart

import 'package:flutter/material.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/whatsapp_launcher.dart';
import 'job_complete_btn.dart';
import 'job_completed_badge.dart';
import 'job_loading_btn.dart';
import 'job_accept_decline_row.dart';

// ============================================================================
// JOB DETAIL FAB ROW — flat surface, no BackdropFilter
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
            _WhatsAppCircleBtn(
              phone:  userPhone,
              isDark: isDark,
              label:  context.tr('worker_jobs.chat_with_client'),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // ── Primary CTA ───────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isTerminal
                    ? JobCompletedBadge(isDark: isDark, context: context)
                    : isLoading
                        ? JobLoadingBtn(accentColor: accentColor)
                        : job.status == ServiceStatus.pending
                            ? JobAcceptDeclineRow(
                                context:   context,
                                onAccept:  onAccept,
                                onDecline: onDecline,
                              )
                            : (job.status == ServiceStatus.accepted ||
                                    job.status == ServiceStatus.inProgress)
                                ? JobCompleteBtn(
                                    accentColor: accentColor,
                                    onTap:       onComplete,
                                    context:     context,
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

// ============================================================================
// _WhatsAppCircleBtn
// White circle with green border — icon is the natural-colour WhatsApp PNG.
// ============================================================================

class _WhatsAppCircleBtn extends StatefulWidget {
  final String phone;
  final bool   isDark;
  final String label;

  const _WhatsAppCircleBtn({
    required this.phone,
    required this.isDark,
    required this.label,
  });

  @override
  State<_WhatsAppCircleBtn> createState() => _WhatsAppCircleBtnState();
}

class _WhatsAppCircleBtnState extends State<_WhatsAppCircleBtn> {
  bool _busy = false;

  Future<void> _launch() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final msg = context.tr('whatsapp.contact_message');
      final ok  = await launchWhatsApp(phone: widget.phone, message: msg);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('whatsapp.open_failed')),
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
    return Semantics(
      button: true,
      label:  widget.label,
      child: GestureDetector(
        onTap: _busy ? null : _launch,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity:  _busy ? 0.5 : 1.0,
          child: Container(
            width:  46,
            height: 46,
            decoration: BoxDecoration(
              // White/dark background → icon colours are clearly visible
              color:  widget.isDark
                  ? const Color(0xFF1B2B1B)
                  : Colors.white,
              shape:  BoxShape.circle,
              border: Border.all(
                color: kWhatsAppGreen.withOpacity(0.55),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color:      kWhatsAppGreen.withOpacity(0.15),
                  blurRadius: 8,
                  offset:     const Offset(0, 2),
                ),
              ],
            ),
            child: _busy
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:       kWhatsAppGreen,
                    ),
                  )
                : Center(
                    // Natural icon — NO color tint
                    child: WhatsAppIcon(size: 24),
                  ),
          ),
        ),
      ),
    );
  }
}
