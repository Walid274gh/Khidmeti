// lib/screens/worker_jobs/widgets/filter_bar_container.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

// ============================================================================
// FILTER BAR CONTAINER — flat surface, no BackdropFilter
// ============================================================================

class FilterBarContainer extends StatelessWidget {
  final bool   isDark;
  final Widget child;

  const FilterBarContainer({
    super.key,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height:    56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: child,
    );
  }
}
