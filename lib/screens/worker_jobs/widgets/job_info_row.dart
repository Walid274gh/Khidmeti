// lib/screens/worker_jobs/widgets/job_info_row.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

class JobInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool mono;
  final bool highlight;

  const JobInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.mono = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    return Row(
      children: [
        Icon(
          icon,
          // [TOKEN FIX]: was raw size: 16 literal — replaced with
          // AppConstants.iconSizeXs (16.0) so it references the token system.
          size: AppConstants.iconSizeXs,
          color: isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: mono ? AppConstants.monoFontFamily : null,
                color: highlight ? accentColor : null,
              ),
        ),
      ],
    );
  }
}
