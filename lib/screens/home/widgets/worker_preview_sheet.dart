// lib/screens/home/widgets/worker_preview_sheet.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/worker_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/whatsapp_launcher.dart';
import 'online_badge.dart';
import 'rating_row.dart';
import 'worker_avatar.dart';

// ============================================================================
// WORKER PREVIEW SHEET — flat surface, no BackdropFilter
//
// FIX (P3): was ConsumerWidget with ref declared but never used in build().
// Converted to StatelessWidget — no Riverpod dependency is needed here.
// ============================================================================

class WorkerPreviewSheet extends StatelessWidget {
  final WorkerModel worker;

  const WorkerPreviewSheet({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = AppTheme.getProfessionColor(worker.profession, isDark);
    final theme  = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingLg,
          AppConstants.paddingMd,
          AppConstants.paddingLg,
          AppConstants.paddingLg,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXxl),
          ),
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle bar ──────────────────────────────────────────
              Center(
                child: Container(
                  width:  40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:        theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // ── Worker info row ─────────────────────────────────────
              Row(
                children: [
                  WorkerAvatar(worker: worker, color: color),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(worker.name,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          context.tr('services.${worker.profession}'),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: color),
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        RatingRow(worker: worker),
                      ],
                    ),
                  ),
                  OnlineBadge(isOnline: worker.isOnline),
                ],
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Action buttons ──────────────────────────────────────
              Row(
                children: [
                  // WhatsApp CTA
                  Expanded(
                    child: _WhatsAppCTA(
                      phone:   worker.phoneNumber,
                      isDark:  isDark,
                      onPressed: () => context.pop(),
                      label:   context.tr('nav.messages'),
                      context: context,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  // View profile
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.pop();
                        context.push('/worker/${worker.id}');
                      },
                      icon:  const Icon(AppIcons.profileOutlined, size: 18),
                      label: Text(context.tr('worker_preview.view_profile')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _WhatsAppCTA — white background, natural icon, green text
// ============================================================================

class _WhatsAppCTA extends StatefulWidget {
  final String       phone;
  final bool         isDark;
  final String       label;
  final VoidCallback onPressed;
  final BuildContext context;

  const _WhatsAppCTA({
    required this.phone,
    required this.isDark,
    required this.label,
    required this.onPressed,
    required this.context,
  });

  @override
  State<_WhatsAppCTA> createState() => _WhatsAppCTAState();
}

class _WhatsAppCTAState extends State<_WhatsAppCTA> {
  bool _loading = false;

  Future<void> _launch() async {
    if (_loading) return;
    widget.onPressed();
    setState(() => _loading = true);
    try {
      final msg = widget.context.tr('whatsapp.contact_message');
      final ok  = await launchWhatsApp(phone: widget.phone, message: msg);
      if (!ok && mounted) {
        ScaffoldMessenger.of(widget.context).showSnackBar(
          SnackBar(
            content: Text(widget.context.tr('whatsapp.open_failed')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppConstants.buttonHeightMd,
      child: ElevatedButton(
        onPressed: _loading ? null : _launch,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isDark
              ? const Color(0xFF1B2B1B)
              : Colors.white,
          foregroundColor: kWhatsAppGreen,
          elevation:       0,
          side: BorderSide(
            color: kWhatsAppGreen.withOpacity(0.55),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: _loading
            ? SizedBox(
                width:  18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kWhatsAppGreen,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WhatsAppIcon(size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color:      kWhatsAppGreen,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
