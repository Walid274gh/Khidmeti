// lib/extensions/go_router_extension.dart
//
// Extracted from app_router.dart — extension methods belong in lib/extensions/,
// not inside a router configuration file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/logger.dart';

/// Convenience navigation helpers on [BuildContext].
///
/// Import this file in any screen that calls [navigateTo] or [navigateBack]
/// instead of importing the full router configuration.
extension GoRouterExtension on BuildContext {
  void navigateTo(String route) {
    AppLogger.navigation('Current', route);
    go(route);
  }

  void navigateBack() {
    AppLogger.debug('Navigating back');
    pop();
  }

  bool get canNavigateBack => canPop();
}
