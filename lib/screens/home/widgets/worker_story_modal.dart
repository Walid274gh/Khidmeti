// lib/screens/home/widgets/worker_story_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/worker_home_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'home_worker_section.dart';

// ─── Dimensions ───────────────────────────────────────────────────────────────
const double _kTopPeek        = 72.0;  // Home screen peeking above — story feel
const double _kTopRadius      = 24.0;
const double _kDragHandleW    = 40.0;
const double _kDragHandleH    =  4.0;
const double _kCloseSize      = 32.0;
const double _kStatusDotSize  =  8.0;
const double _kDismissVelocity = 400.0; // px/s threshold for swipe-to-dismiss

// ============================================================================
// WORKER STORY MODAL
//
// Design: Instagram/WhatsApp story pattern.
//   • Navigator.push (not showModalBottomSheet) → true page-navigation feel,
//     back button works, proper Hero transition slot.
//   • Translucent barrier reveals the home screen above (_kTopPeek = 72 px)
//     reinforcing the "story opened from home" metaphor.
//   • Slide-up with easeOutCubic, slide-down on pop.
//   • Swipe-down fast → dismiss (velocity threshold: _kDismissVelocity).
//   • Contains HomeWorkerSection unmodified — single source of truth.
// ============================================================================

class WorkerStoryModal {
  static void show(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque:              false,
        barrierColor:        Colors.black.withOpacity(0.45),
        barrierDismissible:  true,
        transitionDuration:  const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const _WorkerStoryPage(),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end:   Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve:  Curves.easeOutCubic,
          ));
          // Fade the barrier in simultaneously
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class _WorkerStoryPage extends ConsumerStatefulWidget {
  const _WorkerStoryPage();

  @override
  ConsumerState<_WorkerStoryPage> createState() => _WorkerStoryPageState();
}

class _WorkerStoryPageState extends ConsumerState<_WorkerStoryPage> {
  // Tracks drag offset for visual feedback while swiping down
  double _dragOffset = 0.0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0) {
      setState(() => _dragOffset += details.delta.dy);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity > _kDismissVelocity || _dragOffset > 160) {
      Navigator.of(context).pop();
    } else {
      // Snap back
      setState(() => _dragOffset = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final isOnline   = ref.watch(
      workerHomeControllerProvider.select((s) => s.isOnline),
    );
    final statusColor = isOnline
        ? AppTheme.onlineGreen
        : AppTheme.recordingRed;

    final bg     = isDark ? AppTheme.darkBackground  : AppTheme.lightBackground;
    final border = isDark ? AppTheme.darkBorder       : AppTheme.lightBorder;
    final text   = isDark ? AppTheme.darkText         : AppTheme.lightText;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        // Tap the peek area (top _kTopPeek px) → dismiss
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Column(
          children: [
            // ── Peek zone — home screen shows through ─────────────────────
            const SizedBox(height: _kTopPeek),

            // ── Story card ────────────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                // Prevent tap-dismiss from propagating through the card
                onTap: () {},
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd:    _onDragEnd,
                child: Transform.translate(
                  offset: Offset(0, _dragOffset.clamp(0.0, 200.0)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(_kTopRadius),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withOpacity(
                            isDark ? 0.40 : 0.18,
                          ),
                          blurRadius: 24,
                          offset:     const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ── Drag handle ──────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 4),
                          child: Container(
                            width:  _kDragHandleW,
                            height: _kDragHandleH,
                            decoration: BoxDecoration(
                              color:        border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // ── Header ──────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingLg,
                            vertical:   AppConstants.spacingSm,
                          ),
                          child: Row(
                            children: [
                              // Status dot
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width:  _kStatusDotSize,
                                height: _kStatusDotSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color:      statusColor.withOpacity(0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingSm),

                              // Title
                              Text(
                                context.tr('worker_home.story_title'),
                                style: TextStyle(
                                  fontSize:   AppConstants.fontSizeLg,
                                  fontWeight: FontWeight.w700,
                                  color:      text,
                                  letterSpacing: -0.4,
                                ),
                              ),

                              const Spacer(),

                              // Status pill
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingMd,
                                  vertical:   AppConstants.spacingXs,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(
                                    isDark ? 0.15 : 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusCircle,
                                  ),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.30),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  isOnline
                                      ? context.tr('worker_home.status_online')
                                      : context.tr('worker_home.status_offline'),
                                  style: TextStyle(
                                    fontSize:   AppConstants.fontSizeXs,
                                    fontWeight: FontWeight.w700,
                                    color:      statusColor,
                                  ),
                                ),
                              ),

                              const SizedBox(width: AppConstants.spacingSm),

                              // Close button
                              Semantics(
                                label:  context.tr('common.close'),
                                button: true,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width:  _kCloseSize,
                                    height: _kCloseSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? AppTheme.darkSurface
                                          : AppTheme.lightSurfaceVariant,
                                      border: Border.all(
                                        color: border,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        AppIcons.close,
                                        size:  15,
                                        color: text.withOpacity(0.70),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Worker content — scrollable ──────────────────
                        const Expanded(
                          child: SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            child: HomeWorkerSection(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
