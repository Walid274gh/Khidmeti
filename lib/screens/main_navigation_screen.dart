// lib/screens/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/glass_navigation_bars.dart';
import '../widgets/location_permission_overlay.dart';
import '../providers/home_controller.dart';
import '../providers/user_role_provider.dart';

const int _kHomeIdx       = 0;
const int _kWorkerJobsIdx = 1;
const int _kSettingsIdx   = 2;

class MainNavigationScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const MainNavigationScreen({super.key, required this.navigationShell});

  void _onClientTab(int index) {
    switch (index) {
      case 0: navigationShell.goBranch(_kHomeIdx);     break;
      case 1: navigationShell.goBranch(_kSettingsIdx); break;
    }
  }

  void _onWorkerTab(int index) {
    switch (index) {
      case 0: navigationShell.goBranch(_kHomeIdx);       break;
      case 1: navigationShell.goBranch(_kWorkerJobsIdx); break;
      case 2: navigationShell.goBranch(_kSettingsIdx);   break;
    }
  }

  int _toClientNavIndex(int branch) {
    switch (branch) {
      case _kHomeIdx:     return 0;
      case _kSettingsIdx: return 1;
      default:            return 0;
    }
  }

  int _toWorkerNavIndex(int branch) {
    switch (branch) {
      case _kHomeIdx:       return 0;
      case _kWorkerJobsIdx: return 1;
      case _kSettingsIdx:   return 2;
      default:              return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWorker      = ref.watch(cachedUserRoleProvider) == UserRole.worker;
    final branchIndex   = navigationShell.currentIndex;
    final selectedIndex = isWorker
        ? _toWorkerNavIndex(branchIndex)
        : _toClientNavIndex(branchIndex);

    final isMapFullscreen = ref.watch(
      homeControllerProvider.select((s) => s.isMapFullscreen),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Re-apply edge-to-edge on every rebuild so no branch can override it.
    // This is the only reliable way to prevent individual screens from
    // flashing the system nav bar back to a solid colour.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor:        Colors.transparent,
        systemNavigationBarDividerColor:      Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarColor:                  Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return Scaffold(
      extendBody:             true,
      extendBodyBehindAppBar: true,
      body: LocationPermissionGate(child: navigationShell),
      bottomNavigationBar: isMapFullscreen
          ? null
          : (isWorker
              ? WorkerGlassNavigationBar(
                  currentIndex: selectedIndex,
                  onTap:        _onWorkerTab,
                )
              : UserGlassNavigationBar(
                  currentIndex: selectedIndex,
                  onTap:        _onClientTab,
                )),
    );
  }
}
