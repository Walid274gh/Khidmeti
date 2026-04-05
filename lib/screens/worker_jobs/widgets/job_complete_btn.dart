// lib/screens/worker_jobs/widgets/job_complete_btn.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// FIX (P1 — Engineer): BuildContext context removed from constructor.
// Was: context.tr('worker_jobs.complete_job') using the field.
// Now: context.tr('worker_jobs.complete_job') using the build parameter.
// FIX (Designer P1): was LinearGradient(accentColor → accentColor.withOpacity(0.7)).
// Gradient on action buttons is forbidden. Replaced with solid accent.
// FIX [CRITICAL]: was `color: Colors.black` on icon and text — hardcoded
// contrast against accent background. Replaced with Colors.white so text/icon
// remain legible on both darkAccent (#4F46E5) and lightAccent (#4F46E5).
class JobCompleteBtn extends StatelessWidget {
  final Color        accentColor;
  final VoidCallback onTap;

  const JobCompleteBtn({
    super.key,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  context.tr('worker_jobs.complete_job'),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color:        accentColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            boxShadow: [
              BoxShadow(
                color:      accentColor.withOpacity(0.35),
                blurRadius: 10,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.done_all_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  context.tr('worker_jobs.complete_job'),
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
    );
  }
}
