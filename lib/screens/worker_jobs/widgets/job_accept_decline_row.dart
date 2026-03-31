// lib/screens/worker_jobs/widgets/job_accept_decline_row.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class JobAcceptDeclineRow extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final BuildContext context;

  const JobAcceptDeclineRow({
    super.key,
    required this.onAccept,
    required this.onDecline,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Row(
      children: [
        // Decline
        Expanded(
          child: Semantics(
            button: true,
            label:  context.tr('worker_jobs.decline_job'),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onDecline();
              },
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color:        AppTheme.signOutRed.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  border: Border.all(
                      color: AppTheme.signOutRed.withOpacity(0.30)),
                ),
                child: Center(
                  child: Text(
                    context.tr('worker_jobs.decline_job'),
                    style: TextStyle(
                      color:      AppTheme.signOutRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: AppConstants.spacingSm),

        // Accept — FIX (Designer P1): was LinearGradient(onlineGreen→acceptGreen).
        // Gradient on action buttons is forbidden. Replaced with solid onlineGreen.
        Expanded(
          flex: 2,
          child: Semantics(
            button: true,
            label:  context.tr('worker_jobs.accept_job'),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onAccept();
              },
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color:        AppTheme.onlineGreen,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color:      AppTheme.onlineGreen.withOpacity(0.35),
                      blurRadius: 10,
                      offset:     const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('worker_jobs.accept_job'),
                        style: const TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}