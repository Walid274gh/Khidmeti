// lib/screens/home/widgets/voice_search_sheet.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/search_intent.dart';
import '../../../providers/home_search_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// VOICE SEARCH SHEET
//
// Audio-direct path: AudioService records → bytes sent to Gemini 2.5 Flash-Lite.
// No STT — Gemini handles Algerian Darija natively.
//
// States driven by HomeSearchStatus:
//   idle / listening  → orb pulses + waveform + recording timer
//   extracting / searching → orb switches to AI spinner
//   results           → _VoiceResultPill + confirm row
//   error             → error message + retry button
//
// Auto-stops at [_kMaxRecordingSeconds] to cap token cost.
// ============================================================================

// Max recording duration — 30 s = 960 audio tokens max (cost-aware cap).
const int _kMaxRecordingSeconds = 30;

class VoiceSearchSheet extends StatelessWidget {
  const VoiceSearchSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => const VoiceSearchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) => const _VoiceSheetBody();
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _VoiceSheetBody extends ConsumerStatefulWidget {
  const _VoiceSheetBody();

  @override
  ConsumerState<_VoiceSheetBody> createState() => _VoiceSheetBodyState();
}

class _VoiceSheetBodyState extends ConsumerState<_VoiceSheetBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;

  // Local recording timer — drives the elapsed display and auto-stop.
  // Widget-level state only: does not touch HomeSearchController fields.
  Timer?   _elapsedTimer;
  Timer?   _autoStopTimer;
  int      _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    // Capture the notifier reference synchronously — before any autoDispose
    // rebuild could swap it — then start recording after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(homeSearchControllerProvider.notifier).startListening();
      _startElapsedTimer();
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _autoStopTimer?.cancel();
    _pulseCtrl.dispose();
    // FIX (P0 — AI Cost / Cross-Screen Flow): Previously called reset()
    // unconditionally, which destroyed search state even on the SUCCESS path:
    //   user taps "See Workers" → applyToMap() → Navigator.pop() →
    //   dispose() → reset() ← clears the map state we just applied.
    //
    // Fix: only reset when the session did NOT produce results (i.e. the user
    // cancelled, an error occurred, or the sheet closed mid-recording).
    // On the results path applyToMap() has already written the intent to the
    // map controller — leave that state intact.
    try {
      final status =
          ref.read(homeSearchControllerProvider).status;
      if (status != HomeSearchStatus.results) {
        ref.read(homeSearchControllerProvider.notifier).reset();
      }
    } catch (_) {
      // Provider may already be disposed — safe to ignore.
    }
    super.dispose();
  }

  // ── Local timer helpers ───────────────────────────────────────────────────

  void _startElapsedTimer() {
    _elapsedSeconds = 0;
    _elapsedTimer?.cancel();
    _autoStopTimer?.cancel();

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });

    // Auto-stop at cap to control token cost
    _autoStopTimer = Timer(
      Duration(seconds: _kMaxRecordingSeconds),
      () {
        if (mounted &&
            ref.read(homeSearchControllerProvider).status ==
                HomeSearchStatus.listening) {
          _stopAndProcess();
        }
      },
    );
  }

  void _stopTimers() {
    _elapsedTimer?.cancel();
    _autoStopTimer?.cancel();
    _elapsedTimer  = null;
    _autoStopTimer = null;
  }

  String get _elapsedLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _stopAndProcess() {
    _stopTimers();
    ref.read(homeSearchControllerProvider.notifier).stopListening();
  }

  void _retryListening() {
    _stopTimers();
    ref.read(homeSearchControllerProvider.notifier).reset();
    ref.read(homeSearchControllerProvider.notifier).startListening();
    _startElapsedTimer();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final accent      = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final searchState = ref.watch(homeSearchControllerProvider);
    final isListening = searchState.status == HomeSearchStatus.listening;
    final isLoading   = searchState.isLoading;
    final hasResult   = searchState.hasResults;
    final hasError    = searchState.hasError;
    final intent      = searchState.lastIntent;

    return Container(
      decoration: BoxDecoration(
        color:        isDark
            ? AppTheme.darkBackground
            : AppTheme.lightBackground,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXxl)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLg,
            vertical:   AppConstants.paddingMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ────────────────────────────────────────────────────
              Center(
                child: Container(
                  width:  AppConstants.sheetHandleWidth,
                  height: AppConstants.sheetHandleHeight,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusXs),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // ── Status label ──────────────────────────────────────────────
              Text(
                searchState.status == HomeSearchStatus.idle
                    ? context.tr('home.voice_starting')
                    : isListening
                        ? '$_elapsedLabel  •  ${context.tr('home.voice_listening')}'
                        : isLoading
                            ? context.tr('home.voice_processing')
                            : hasResult
                                ? context.tr('home.voice_done')
                                : hasError
                                    ? context.tr('home.voice_error')
                                    : context.tr('home.voice_starting'),
                style: TextStyle(
                  fontSize:      AppConstants.fontSizeXs,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isLoading || hasResult ? AppTheme.aiPrimary : accent,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // ── Orb ───────────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _pulse,
                builder:   (_, child) => Transform.scale(
                  scale: isListening ? _pulse.value : 1.0,
                  child: child,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width:  88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isLoading || hasResult
                                ? AppTheme.aiPrimary
                                : accent)
                            .withOpacity(0.12),
                      ),
                    ),
                    Container(
                      width:  72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isLoading || hasResult
                                ? AppTheme.aiPrimary
                                : accent)
                            .withOpacity(0.20),
                      ),
                    ),
                    Container(
                      width:  58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLoading || hasResult
                            ? AppTheme.aiPrimary
                            : accent,
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width:  22,
                                height: 22,
                                child:  CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:       Colors.white,
                                ),
                              )
                            : Icon(
                                hasResult ? AppIcons.ai : AppIcons.mic,
                                size:  26,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // ── Waveform (listening only) ──────────────────────────────────
              if (isListening)
                _Waveform(color: accent, isAnimating: true),

              const SizedBox(height: AppConstants.spacingMd),

              // ── Recording feedback ────────────────────────────────────────
              // Shows elapsed time while recording — no transcript (audio-direct)
              SizedBox(
                height: 48,
                child: Center(
                  child: isListening
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _elapsedLabel,
                              style: TextStyle(
                                fontSize:   AppConstants.fontSizeXxl,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkText
                                    : AppTheme.lightText,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            Text(
                              'max $_kMaxRecordingSeconds s',
                              style: TextStyle(
                                fontSize: AppConstants.fontSizeXs,
                                color: isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // ── Result confirm ────────────────────────────────────────────
              if (hasResult && intent != null) ...[
                _VoiceResultPill(intent: intent, isDark: isDark),
                const SizedBox(height: AppConstants.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _retryListening,
                        icon:  const Icon(AppIcons.mic, size: 16),
                        label: Text(context.tr('home.voice_retry')),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ref
                              .read(homeSearchControllerProvider.notifier)
                              .applyToMap();
                          Navigator.pop(context);
                        },
                        child: Text(context.tr('home.ai_search_see_workers')),
                      ),
                    ),
                  ],
                ),
              ]

              // ── Error ──────────────────────────────────────────────────────
              else if (hasError) ...[
                Text(
                  searchState.error == 'mic_unavailable'
                      ? context.tr('home.voice_mic_unavailable')
                      : context.tr('home.search_error'),
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeSm,
                    color: isDark ? AppTheme.darkError : AppTheme.lightError,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                ElevatedButton.icon(
                  onPressed: _retryListening,
                  icon:  const Icon(AppIcons.mic, size: 16),
                  label: Text(context.tr('home.voice_retry')),
                ),
              ]

              // ── Listening controls ─────────────────────────────────────────
              else if (isListening) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _stopTimers();
                          ref
                              .read(homeSearchControllerProvider.notifier)
                              .reset();
                          Navigator.pop(context);
                        },
                        child: Text(context.tr('common.cancel')),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: ElevatedButton.icon(
                        // Enabled after at least 2 seconds of audio
                        onPressed: _elapsedSeconds >= 2
                            ? _stopAndProcess
                            : null,
                        icon:  const Icon(AppIcons.stop, size: 16),
                        label: Text(context.tr('home.voice_search_now')),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppConstants.paddingMd),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Waveform ──────────────────────────────────────────────────────────────────

class _Waveform extends StatefulWidget {
  final Color color;
  final bool  isAnimating;

  const _Waveform({required this.color, required this.isAnimating});

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const List<double> _heights = [
    8.0, 18.0, 28.0, 36.0, 42.0, 36.0, 28.0, 18.0, 8.0
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder:   (_, __) => Row(
          mainAxisAlignment:  MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_heights.length, (i) {
            final phase  = (i / _heights.length) * 2 * math.pi;
            final factor = widget.isAnimating
                ? (0.4 +
                    0.6 *
                        (math.sin(
                                    _ctrl.value * 2 * math.pi + phase) +
                                1) /
                            2)
                : 0.3;
            return Container(
              width:  3,
              height: _heights[i] * factor,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color:        widget.color
                    .withOpacity((0.7 + factor * 0.3).clamp(0.0, 1.0)),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Voice result pill ─────────────────────────────────────────────────────────

class _VoiceResultPill extends StatelessWidget {
  final SearchIntent intent;
  final bool         isDark;

  const _VoiceResultPill({required this.intent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final color  = AppTheme.getProfessionColor(
        intent.profession ?? '', isDark);
    final icon   = intent.profession != null
        ? AppTheme.getProfessionIcon(intent.profession!)
        : AppIcons.search;
    final pct    = (intent.confidence * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color:        accent.withOpacity(isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border:       Border.all(
            color: accent.withOpacity(isDark ? 0.20 : 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color:  color.withOpacity(0.14),
              shape:  BoxShape.circle,
            ),
            child: Center(child: Icon(icon, size: 18, color: color)),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intent.profession != null
                      ? context.tr('services.${intent.profession}')
                      : context.tr('home.filter_all'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                ),
                if (intent.isUrgent)
                  Text(
                    context.tr('home.search_urgent_badge'),
                    style: TextStyle(
                      fontSize:   AppConstants.fontSizeXs,
                      fontWeight: FontWeight.w700,
                      color:      AppTheme.recordingRed,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingSm,
              vertical:   AppConstants.spacingXs,
            ),
            decoration: BoxDecoration(
              color:        accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusXs),
            ),
            child: Text(
              '$pct%',
              style: TextStyle(
                fontSize:   AppConstants.fontSizeXs,
                fontWeight: FontWeight.w700,
                color:      accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

