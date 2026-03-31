// lib/screens/home/widgets/rating_row.dart

import 'package:flutter/material.dart';

import '../../../models/worker_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

// ============================================================================
// RATING ROW
// ============================================================================

class RatingRow extends StatelessWidget {
  final WorkerModel worker;
  const RatingRow({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    // FIX: was hardcoded AppTheme.darkAccent — always amber-dark regardless of
    // theme. Use the correct accent for the current mode.
    final starColor  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Row(
      children: [
        // FIX: was Icons.star (raw icon). Use AppIcons.ratingFilled.
        Icon(AppIcons.ratingFilled, color: starColor, size: 14),
        const SizedBox(width: 3),
        Text(
          worker.averageRating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Text(
          ' (${worker.ratingCount})',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

