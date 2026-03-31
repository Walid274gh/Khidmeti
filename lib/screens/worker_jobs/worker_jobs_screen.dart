// lib/screens/worker_jobs/worker_jobs_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import 'widgets/browse_tab.dart';
import 'widgets/missions_tab.dart';
import 'widgets/my_bids_tab.dart';



class WorkerJobsScreen extends ConsumerStatefulWidget {
  const WorkerJobsScreen({super.key});

  @override
  ConsumerState<WorkerJobsScreen> createState() => _WorkerJobsScreenState();
}

class _WorkerJobsScreenState extends ConsumerState<WorkerJobsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // FIX (Performance): removed addListener(() => setState((){})) — was
    // triggering a full root rebuild on every tab swipe for no reason.
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor:                      Colors.transparent,
        statusBarIconBrightness:             isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:                 isDark ? Brightness.dark  : Brightness.light,
        systemNavigationBarColor:            Colors.transparent,
        systemNavigationBarDividerColor:     Colors.transparent,
        systemNavigationBarIconBrightness:   isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: SafeArea(
          child: Column(
            children: [
              _JobsHeader(
                isDark: isDark,
                accent: accent,
                tabController: _tabController,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    BrowseTab(isDark: isDark, accent: accent),
                    MissionsTab(isDark: isDark, accent: accent),
                    MyBidsTab(isDark: isDark, accent: accent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _JobsHeader
// Private to this file — used only by WorkerJobsScreen.
// ============================================================================

class _JobsHeader extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final TabController tabController;

  const _JobsHeader({
    required this.isDark,
    required this.accent,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMd,
              AppConstants.paddingMd,
              AppConstants.paddingMd,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('nav.jobs'),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          // FIX (Designer): font family is resolved from ThemeData — no
          // hardcoded 'Inter' to avoid breaking Arabic tab labels.
          TabBar(
            controller: tabController,
            indicatorColor: accent,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor:
                isDark ? AppTheme.darkText : AppTheme.lightText,
            unselectedLabelColor: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
            labelStyle: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            unselectedLabelStyle: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w400),
            tabs: [
              Tab(text: context.tr('worker_browse.tab_browse')),
              Tab(text: context.tr('worker_missions.tab_missions')),
              Tab(text: context.tr('worker_my_bids.tab_bids')),
            ],
          ),
        ],
      ),
    );
  }
}
