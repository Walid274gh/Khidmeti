// lib/screens/auth/widgets/voice_profession_button.dart
//
// Press-and-hold microphone button for illiterate workers.
// States: idle → recording (max 5s) → processing → success / error
// Communicates detected profession key via [onProfessionDetected] callback.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/core_providers.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

enum _VoiceState { idle, recording, processing, success, error }

class VoiceProfessionButton extends ConsumerStatefulWidget {
  final ValueChanged<String> onProfessionDetected;
  const VoiceProfessionButton({super.key, required this.onProfessionDetected});

  @override
  ConsumerState<VoiceProfessionButton> createState() =>
      _VoiceProfessionButtonState();
}

class _VoiceProfessionButtonState
    extends ConsumerState<VoiceProfessionButton>
    with TickerProviderStateMixin {

  _VoiceState _state = _VoiceState.idle;
  String?     _detectedLabel;
  String?     _errorMsg;

  static const int _maxSeconds = 5;
  Timer? _maxTimer;
  Timer? _elapsedTimer;
  int    _elapsed = 0;

  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _maxTimer?.cancel();
    _elapsedTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_state != _VoiceState.idle) return;
    final audioService = ref.read(audioServiceProvider);
    final hasPerm      = await audioService.hasAudioPermission();
    if (!mounted) return;
    if (!hasPerm) {
      setState(() { _state = _VoiceState.error; _errorMsg = context.tr('home.voice_mic_unavailable'); });
      _scheduleReset();
      return;
    }
    HapticFeedback.mediumImpact();
    try {
      await audioService.startRecording();
    } catch (_) {
      if (mounted) { setState(() { _state = _VoiceState.error; _errorMsg = context.tr('errors.generic'); }); _scheduleReset(); }
      return;
    }
    if (!mounted) return;
    setState(() { _state = _VoiceState.recording; _elapsed = 0; });
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => _elapsed++); });
    _maxTimer = Timer(const Duration(seconds: _maxSeconds), _stop);
  }

  Future<void> _stop() async {
    _maxTimer?.cancel(); _elapsedTimer?.cancel();
    if (_state != _VoiceState.recording || !mounted) return;
    setState(() => _state = _VoiceState.processing);
    HapticFeedback.lightImpact();
    final audioService = ref.read(audioServiceProvider);
    final aiService    = ref.read(localAiServiceProvider);
    try {
      final path = await audioService.stopRecording();
      if (path == null || !mounted) { _setError(context.tr('errors.generic')); return; }
      final file = File(path);
      if (!await file.exists() || !mounted) { _setError(context.tr('errors.generic')); return; }
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      final intent = await aiService.extractFromAudio(bytes, mime: 'audio/m4a');
      if (!mounted) return;
      if (intent.profession != null && intent.profession!.isNotEmpty) {
        setState(() { _state = _VoiceState.success; _detectedLabel = intent.profession; });
        HapticFeedback.mediumImpact();
        widget.onProfessionDetected(intent.profession!);
        _scheduleReset(delay: const Duration(seconds: 3));
      } else {
        _setError(context.tr('errors.voice_profession_not_found'));
      }
    } catch (_) {
      if (mounted) _setError(context.tr('errors.generic'));
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() { _state = _VoiceState.error; _errorMsg = msg; });
    _scheduleReset();
  }

  void _scheduleReset({Duration delay = const Duration(seconds: 3)}) {
    Timer(delay, () { if (mounted) setState(() { _state = _VoiceState.idle; _errorMsg = null; _detectedLabel = null; }); });
  }

  Color _color() {
    switch (_state) {
      case _VoiceState.idle:       return Theme.of(context).brightness == Brightness.dark ? AppTheme.darkAccent : AppTheme.lightAccent;
      case _VoiceState.recording:  return AppTheme.recordingRed;
      case _VoiceState.processing: return AppTheme.warningAmber;
      case _VoiceState.success:    return AppTheme.onlineGreen;
      case _VoiceState.error:      return Theme.of(context).brightness == Brightness.dark ? AppTheme.darkError : AppTheme.lightError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = _color();

    return Semantics(
      button: true,
      label:  context.tr('worker_profile.voice_hint'),
      child: GestureDetector(
        onTapDown:   _state == _VoiceState.idle      ? (_) => _start() : null,
        onTapUp:     _state == _VoiceState.recording ? (_) => _stop()  : null,
        onTapCancel: _state == _VoiceState.recording ? _stop           : null,
        child: AnimatedContainer(
          duration: AppConstants.animDurationMicro,
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.10 : 0.08),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(color: color.withOpacity(0.30), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) => Transform.scale(
                  scale: _state == _VoiceState.recording ? _pulse.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: AppConstants.buttonHeightMd, height: AppConstants.buttonHeightMd,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: color,
                    boxShadow: _state == _VoiceState.recording ? [BoxShadow(color: color.withOpacity(0.40), blurRadius: 16, offset: const Offset(0, 4))] : null,
                  ),
                  child: Center(child: _iconFor()),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Flexible(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_labelFor(context), style: TextStyle(fontSize: AppConstants.fontSizeMd, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkText : AppTheme.lightText)),
                  if (_state == _VoiceState.recording) ...[
                    const SizedBox(height: AppConstants.spacingXs),
                    LinearProgressIndicator(value: _elapsed / _maxSeconds, backgroundColor: color.withOpacity(0.20), valueColor: AlwaysStoppedAnimation(color), minHeight: 3, borderRadius: BorderRadius.circular(2)),
                  ] else if (_state == _VoiceState.error && _errorMsg != null) ...[
                    const SizedBox(height: 2),
                    Text(_errorMsg!, style: TextStyle(fontSize: AppConstants.fontSizeSm, color: color), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconFor() {
    switch (_state) {
      case _VoiceState.idle:
      case _VoiceState.recording:  return const Icon(AppIcons.mic, color: Colors.white, size: 20);
      case _VoiceState.processing: return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)));
      case _VoiceState.success:    return const Icon(Icons.check_rounded, color: Colors.white, size: 20);
      case _VoiceState.error:      return const Icon(AppIcons.micOff, color: Colors.white, size: 20);
    }
  }

  String _labelFor(BuildContext ctx) {
    switch (_state) {
      case _VoiceState.idle:       return ctx.tr('worker_profile.voice_hint');
      case _VoiceState.recording:  return '${_maxSeconds - _elapsed}s — ${ctx.tr("home.voice_listening")}';
      case _VoiceState.processing: return ctx.tr('home.voice_processing');
      case _VoiceState.success:    return '✓ ${_detectedLabel ?? ctx.tr("home.voice_done")}';
      case _VoiceState.error:      return ctx.tr('home.voice_error');
    }
  }
}
