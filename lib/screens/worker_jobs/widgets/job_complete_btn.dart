// lib/screens/worker_jobs/widgets/job_complete_btn.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class JobCompleteBtn extends StatelessWidget {
  final Color        accentColor;
  final VoidCallback onTap;
  final BuildContext context;

  const JobCompleteBtn({
    super.key,
    required this.accentColor,
    required this.onTap,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    // FIX (Designer P1): was LinearGradient(accentColor → accentColor.withOpacity(0.7)).
    // Gradient on action buttons is forbidden. Replaced with solid accent.
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
                    color: Colors.black, size: 18),
                const SizedBox(width: 6),
                Text(
                  context.tr('worker_jobs.complete_job'),
                  style: const TextStyle(
                    color:      Colors.black,
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