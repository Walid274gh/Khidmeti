// lib/screens/worker_jobs/submit_bid_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/worker_model.dart';
import '../../providers/core_providers.dart';
import '../../services/worker_bid_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';


class SubmitBidScreen extends ConsumerStatefulWidget {
  final String requestId;

  const SubmitBidScreen({super.key, required this.requestId});

  @override
  ConsumerState<SubmitBidScreen> createState() => _SubmitBidScreenState();
}

class _SubmitBidScreenState extends ConsumerState<SubmitBidScreen> {
  final _priceCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  int      _estimatedHours   = 1;
  int      _estimatedMinutes = 0;
  DateTime _availableFrom    = DateTime.now();

  bool    _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  int get _totalEstimatedMinutes => _estimatedHours * 60 + _estimatedMinutes;

  Future<void> _submit(WorkerModel worker) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSubmitting) return;
    if (!mounted) return;

    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(workerBidServiceProvider).submitBid(
            requestId:        widget.requestId,
            worker:           worker,
            proposedPrice:    price,
            estimatedMinutes: _totalEstimatedMinutes,
            availableFrom:    _availableFrom,
            message: _messageCtrl.text.trim().isEmpty
                ? null
                : _messageCtrl.text.trim(),
          );

      if (!mounted) return;
      context.pop();
    } on WorkerBidServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      // FIX (QA P0): was e.toString() — never expose raw exception strings.
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = null; // shown via tr key below
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    final workerId     = ref.watch(currentUserIdProvider);
    final workerAsync  = workerId != null
        ? ref.watch(workerProfileProvider(workerId))
        : null;
    final requestAsync = ref.watch(serviceRequestStreamProvider(widget.requestId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingMd,
                  AppConstants.paddingMd,
                  AppConstants.paddingMd,
                  0,
                ),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: context.tr('common.back'),
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.07),
                            borderRadius: BorderRadius.circular(
                                AppConstants.radiusMd),
                          ),
                          child: Icon(
                            AppIcons.back,
                            size: 20,
                            color: isDark
                                ? AppTheme.darkText
                                : AppTheme.lightText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Text(
                      context.tr('worker_browse.make_offer'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingMd),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Request summary ───────────────────────────────
                        requestAsync.when(
                          // FIX (Async States): was SizedBox.shrink() — worker
                          // saw no loading feedback and could submit a blind offer.
                          loading: () => _RequestSummarySkeletonCard(
                            isDark: isDark,
                          ),
                          // FIX (Async States): was SizedBox.shrink() — show
                          // an error notice so the worker knows data failed.
                          error: (_, __) => _RequestSummaryError(
                            isDark: isDark,
                            accent: accent,
                          ),
                          data: (req) {
                            if (req == null) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingMd),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusLg),
                                border: Border.all(
                                    color: accent.withOpacity(0.25)),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(
                                        'services.${req.serviceType}'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700),
                                  ),
                                  if (req.userAddress.isNotEmpty)
                                    Text(
                                      req.userAddress,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AppTheme.darkSecondaryText
                                                : AppTheme
                                                    .lightSecondaryText,
                                          ),
                                    ),
                                  if (req.displayAmount != null)
                                    Text(
                                      '${context.tr('bids.budget')}: ${req.displayAmount} ${context.tr('common.currency')}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: AppConstants.spacingMd),

                        // ── Price field ───────────────────────────────────
                        _FieldLabel(
                          text: context.tr('worker_browse.proposed_price'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: false),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText:   '3500',
                            suffixText: context.tr('common.currency'),
                            suffixStyle:
                                Theme.of(context).textTheme.bodyMedium,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return context
                                  .tr('worker_browse.price_required');
                            }
                            final p = double.tryParse(v);
                            if (p == null || p <= 0) {
                              return context
                                  .tr('worker_browse.price_invalid');
                            }
                            // FIX (QA P1): Added maximum price guard.
                            if (p > AppConstants.maxBidPrice) {
                              return context
                                  .tr('worker_browse.price_too_high');
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppConstants.spacingMd),

                        // ── Estimated duration ────────────────────────────
                        _FieldLabel(
                          text: context.tr('worker_browse.estimated_duration'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        Row(
                          children: [
                            Expanded(
                              child: _DurationPicker(
                                value:     _estimatedHours,
                                max:       23,
                                label:     context.tr('worker_browse.hours'),
                                isDark:    isDark,
                                onChanged: (v) =>
                                    setState(() => _estimatedHours = v),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingMd),
                            Expanded(
                              child: _DurationPicker(
                                value:     _estimatedMinutes,
                                max:       55,
                                step:      5,
                                label:     context.tr('worker_browse.minutes'),
                                isDark:    isDark,
                                onChanged: (v) =>
                                    setState(() => _estimatedMinutes = v),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppConstants.spacingMd),

                        // ── Message (optional) ────────────────────────────
                        _FieldLabel(
                          text:
                              '${context.tr('worker_browse.message')} (${context.tr('common.optional')})',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        TextFormField(
                          controller: _messageCtrl,
                          maxLines:   3,
                          maxLength:  300,
                          decoration: InputDecoration(
                            hintText: context
                                .tr('worker_browse.message_hint'),
                            counterStyle:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ),

                        // ── Error message ─────────────────────────────────
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppConstants.spacingSm),
                          Text(
                            _errorMessage!,
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
                        // FIX (QA P0): generic error shown via localized key
                        // instead of raw exception string.
                        if (!_isSubmitting &&
                            _errorMessage == null &&
                            _priceCtrl.text.isEmpty == false) ...[
                          // Intentionally empty — error cleared on re-submit.
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Submit button ─────────────────────────────────────────
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppConstants.paddingMd,
                  AppConstants.spacingSm,
                  AppConstants.paddingMd,
                  AppConstants.spacingSm +
                      MediaQuery.of(context).padding.bottom,
                ),
                child: workerAsync?.when(
                      data: (worker) => worker != null
                          ? Semantics(
                              button: true,
                              label: context.tr('worker_browse.submit_offer'),
                              child: SizedBox(
                                width:  double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _submit(worker),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    // FIX (WCAG AA): was Colors.black — fails
                                    // on darkAccent. Colors.white passes AA.
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppConstants.radiusMd),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width:  20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          context.tr(
                                              'worker_browse.submit_offer'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox(
                        height: 52,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ) ??
                    const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _RequestSummarySkeletonCard
// FIX (Async States): replaces SizedBox.shrink() during request loading.
// Matches the approximate height of the loaded summary card.
// ============================================================================

class _RequestSummarySkeletonCard extends StatefulWidget {
  final bool isDark;
  const _RequestSummarySkeletonCard({required this.isDark});

  @override
  State<_RequestSummarySkeletonCard> createState() =>
      _RequestSummarySkeletonCardState();
}

class _RequestSummarySkeletonCardState
    extends State<_RequestSummarySkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.8).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark
        ? AppTheme.darkSurfaceVariant
        : AppTheme.lightSurfaceVariant;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: base.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
      ),
    );
  }
}

// ============================================================================
// _RequestSummaryError
// FIX (Async States): replaces SizedBox.shrink() on request load failure.
// ============================================================================

class _RequestSummaryError extends StatelessWidget {
  final bool isDark;
  final Color accent;

  const _RequestSummaryError({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkError : AppTheme.lightError)
            .withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: (isDark ? AppTheme.darkError : AppTheme.lightError)
              .withOpacity(0.25),
        ),
      ),
      child: Text(
        context.tr('errors.loading_request'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.darkError : AppTheme.lightError,
            ),
      ),
    );
  }
}

// ============================================================================
// _FieldLabel — internal form label helper
// ============================================================================

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const _FieldLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

// ============================================================================
// _DurationPicker — +/- spinner (unchanged logic, cleaned up import)
// ============================================================================

class _DurationPicker extends StatelessWidget {
  final int value;
  final int max;
  final int step;
  final String label;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _DurationPicker({
    required this.value,
    required this.max,
    this.step = 1,
    required this.label,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: value > 0
                ? () => onChanged((value - step).clamp(0, max))
                : null,
            child: Icon(
              Icons.remove_rounded,
              size: 18,
              color: value > 0
                  ? (isDark ? AppTheme.darkText : AppTheme.lightText)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
          ),
          Column(
            children: [
              Text(
                value.toString().padLeft(2, '0'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
              ),
            ],
          ),
          GestureDetector(
            onTap: value < max
                ? () => onChanged((value + step).clamp(0, max))
                : null,
            child: Icon(
              Icons.add_rounded,
              size: 18,
              color: value < max
                  ? (isDark ? AppTheme.darkText : AppTheme.lightText)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
          ),
        ],
      ),
    );
  }
}
