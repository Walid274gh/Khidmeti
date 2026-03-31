// lib/screens/home/widgets/home_quick_actions.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/home_controller.dart';
import '../../../providers/user_role_provider.dart';
import '../../../providers/worker_home_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'home_categories_sheet.dart';
import 'home_cta_button.dart';
import 'home_service_grid.dart';

// ============================================================================
// HOME QUICK ACTIONS
//
// Layout (top → bottom, no dead space):
//   ① "Nos services" label + horizontal service grid
//      └─ Workers see a "Vous" chip prepended (story-avatar pattern).
//         Green ring = En ligne, Red ring = Hors ligne.
//         Tap → WorkerStoryModal (full-screen page).
//   ② Subtle divider
//   ③ CTA button — single primary action
//
// This widget lives inside a SingleChildScrollView (home_screen.dart),
// so it must NOT have Spacers or unbounded height — use mainAxisSize.min.
// ============================================================================

class HomeQuickActions extends ConsumerWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeFilter = ref.watch(
      homeControllerProvider.select((s) => s.activeServiceFilter),
    );

    // ── Worker status ────────────────────────────────────────────────────────
    // Both providers are always watched (stable watch count — Riverpod rule).
    // workerIsOnline is only forwarded to the grid when isWorker is true,
    // so non-workers never trigger unnecessary worker UI rebuilds.
    final isWorker = ref.watch(cachedUserRoleProvider) == UserRole.worker;
    final workerIsOnline = ref.watch(
      workerHomeControllerProvider.select((s) => s.isOnline),
    );

    return Column(
      mainAxisSize:       MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Services section ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingLg,
            // FIX (Spacing): increased top breathing room between the
            // AdvancedSearchBar and the "NOS SERVICES" section from
            // paddingMd (16) to paddingLg (24).
            AppConstants.paddingLg,
            AppConstants.paddingLg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section label + "Voir tout"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('home.our_services'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                  ),
                  Semantics(
                    button: true,
                    label:  context.tr('home.see_all'),
                    child: GestureDetector(
                      onTap: () => HomeCategoriesSheet.show(
                        context,
                        (filter) {
                          ref
                              .read(homeControllerProvider.notifier)
                              .toggleServiceFilter(filter);
                          if (filter != null) {
                            ref
                                .read(homeControllerProvider.notifier)
                                .enterMapFullscreen();
                          }
                        },
                      ),
                      child: Text(
                        context.tr('home.see_all'),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                              color:      isDark
                                  ? AppTheme.darkText
                                  : AppTheme.lightAccent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // Scrollable service chips — "Vous" chip prepended for workers
              HomeServiceGrid(
                activeFilter:    activeFilter,
                isWorker:        isWorker,
                workerIsOnline:  workerIsOnline,
                onFilterChanged: (filter) {
                  ref
                      .read(homeControllerProvider.notifier)
                      .toggleServiceFilter(filter);
                  if (filter != null) {
                    ref
                        .read(homeControllerProvider.notifier)
                        .enterMapFullscreen();
                  }
                },
              ),
            ],
          ),
        ),

        // ── Visual separator — with extra breathing room above banner ─────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLg,
            // FIX (Spacing): increased vertical padding around the divider
            // from paddingMd (16) to give the CTA banner more whitespace.
            vertical: AppConstants.paddingLg,
          ),
          child: Divider(
            height:    1,
            thickness: 1,
            color: isDark
                ? AppTheme.darkBorder.withOpacity(0.35)
                : AppTheme.lightBorder,
          ),
        ),

        // ── CTA button ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingLg,
            0,
            AppConstants.paddingLg,
            AppConstants.paddingSm,
          ),
          child: const HomeCtaButton(),
        ),
      ],
    );
  }
}
