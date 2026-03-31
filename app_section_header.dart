// lib/widgets/app_section_header.dart

import 'package:flutter/material.dart';

/// A consistent uppercase section label used across About, Help,
/// Notifications, and Settings screens.
///
/// Renders [label] in `labelSmall` style, uppercased, with 1.2 letter-spacing
/// and a 4-dp directional start-padding (RTL-safe via [EdgeInsetsDirectional]).
class AppSectionHeader extends StatelessWidget {
  final String label;

  const AppSectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight:    FontWeight.w700,
              color:         Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}
