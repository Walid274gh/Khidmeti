// lib/screens/service_request/rating_screen.dart
//
// [C2] FIX: height: 52 (submit button) → AppConstants.buttonHeightMd (48dp).
// [W4] FIX: foregroundColor: Colors.black → AppTheme.lightText.
//      Also color: Colors.black in spinner + label text → AppTheme.lightText.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/core_providers.dart';
import '../../providers/rating_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/back_button.dart';


class RatingScreen extends ConsumerStatefulWidget {
  final String requestId;

  const RatingScreen({super.key, required this.requestId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _starLabel(BuildContext context, int stars) {
    return switch (stars) {
      1 => context.tr('rating.label_1'),
      2 => context.tr('rating.label_2'),
      3 => context.tr('rating.label_3'),
      4 => context.tr('rating.label_4'),
      5 => context.tr('rating.label_5'),
      _ => context.tr('rating.tap_to_rate'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final accent       = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final state        = ref.watch(ratingControllerProvider(widget.requestId));
    final notifier     = ref.read(ratingControllerProvider(widget.requestId).notifier);
    final requestAsync = ref.watch(serviceRequestStreamProvider(widget.requestId));

    ref.listen<RatingState>(
      ratingControllerProvider(widget.requestId),
      (_, next) {
        if (next.success && mounted) context.pop();
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppConstants.paddingMd,
                    AppConstants.paddingMd,
                    AppConstants.paddingMd,
                    0),
                child: Row(
                  children: [
                    AppBackButton(isDark: isDark),
                    const SizedBox(width: AppConstants.spacingMd),
                    Text(
                      context.tr('rating.title'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    AppConstants.paddingMd,
                    AppConstants.spacingXl,
                    AppConstants.paddingMd,
                    AppConstants.spacingXl +
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Worker avatar + name + service type
                      requestAsync.when(
                        data: (req) => req?.workerName != null
                            ? Column(
                                children: [
                                  Container(
                                    width:  68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        req!.workerName![0].toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color:      accent,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppConstants.spacingMd),
                                  Text(
                                    req.workerName!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    context.tr('services.${req.serviceType}'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? AppTheme.darkSecondaryText
                                              : AppTheme.lightSecondaryText,
                                        ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error:   (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // Stars row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final filled = i < state.stars;
                          return Semantics(
                            button: true,
                            label:  _starLabel(context, i + 1),
                            child: GestureDetector(
                              onTap: () => notifier.setStars(i + 1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacingSm),
                                child: Icon(
                                  filled
                                      ? AppIcons.ratingFilled
                                      : AppIcons.ratingOutlined,
                                  size:  40,
                                  color: filled
                                      ? AppTheme.warningAmber
                                      : (isDark
                                          ? AppTheme.darkBorder
                                          : AppTheme.lightBorder),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _starLabel(context, state.stars),
                          key:   ValueKey(state.stars),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: state.stars > 0
                                    ? AppTheme.warningAmber
                                    : (isDark
                                        ? AppTheme.darkSecondaryText
                                        : AppTheme.lightSecondaryText),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // Comment field
                      TextField(
                        controller:      _commentCtrl,
                        maxLines:        4,
                        maxLength:       400,
                        decoration: InputDecoration(
                          hintText: context.tr('rating.comment_hint'),
                          counterStyle:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                        textInputAction: TextInputAction.done,
                      ),

                      // Error message from controller
                      if (state.errorKey != null) ...[
                        const SizedBox(height: AppConstants.spacingSm),
                        Text(
                          context.tr(state.errorKey!),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? AppTheme.darkError
                                    : AppTheme.lightError,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Submit button ────────────────────────────────────────────
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppConstants.paddingMd,
                  AppConstants.spacingSm,
                  AppConstants.paddingMd,
                  AppConstants.spacingSm +
                      MediaQuery.of(context).padding.bottom,
                ),
                child: SizedBox(
                  width:  double.infinity,
                  // [C2] FIX: height: 52 → buttonHeightMd (48dp)
                  height: AppConstants.buttonHeightMd,
                  child: ElevatedButton(
                    onPressed: state.canSubmit
                        ? () => notifier.submit(
                              comment: _commentCtrl.text.trim().isEmpty
                                  ? null
                                  : _commentCtrl.text.trim(),
                            )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      // [W4] FIX: Colors.black → AppTheme.lightText
                      foregroundColor: AppTheme.lightText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMd),
                      ),
                    ),
                    child: state.isSubmitting
                        ? SizedBox(
                            width:  AppConstants.spinnerSizeLg,
                            height: AppConstants.spinnerSizeLg,
                            child:  CircularProgressIndicator(
                                strokeWidth: 2,
                                // [W4] FIX: Colors.black → AppTheme.lightText
                                color: AppTheme.lightText),
                          )
                        : Text(
                            context.tr('rating.submit'),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  // [W4] FIX: Colors.black → AppTheme.lightText
                                  color:      AppTheme.lightText,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
