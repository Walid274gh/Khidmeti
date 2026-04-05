// lib/screens/worker_jobs/widgets/job_meta_chip.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

class JobMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color color;

  const JobMetaChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusXs + 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            // FIX [WARN]: was `fontSize: 10` inline — bypasses textTheme.
            // Now delegates to textTheme.labelSmall (10sp in this project's
            // theme) so size responds to user accessibility settings.
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:      color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
