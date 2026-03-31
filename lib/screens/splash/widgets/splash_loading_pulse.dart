// lib/screens/splash/widgets/splash_loading_pulse.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';


const double _kDotSize = 8.0;
const double _kBounceHeight = 6.0;
const Duration _kDotDuration = Duration(milliseconds: 700);
const Duration _kStaggerDelay = Duration(milliseconds: 180);

class SplashLoadingPulse extends StatefulWidget {
  final Color color;

  /// Accessibility label announced by screen readers.
  /// Pass `context.tr('common.loading')` from the parent widget.
  final String label;

  const SplashLoadingPulse({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  State<SplashLoadingPulse> createState() => _SplashLoadingPulseState();
}

class _SplashLoadingPulseState extends State<SplashLoadingPulse>
    with TickerProviderStateMixin {
  // One controller per dot — enables independent phase offset via delayed start.
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _offsets;
  late final List<Animation<double>> _opacities;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      3,
      (_) => AnimationController(vsync: this, duration: _kDotDuration),
    );

    _offsets = _controllers.map((c) {
      return Tween<double>(begin: 0.0, end: -_kBounceHeight).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    _opacities = _controllers.map((c) {
      return Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    // Start each dot with a staggered delay to create the wave effect.
    // The stagger order is always LTR in controller-index space; the display
    // order is reversed in build() for RTL locales.
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(_kStaggerDelay * i, () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RTL FIX: reverse the visual order of dots for RTL locales so the wave
    // travels from right to left (start of reading direction → end).
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final displayIndices = isRTL ? [2, 1, 0] : [0, 1, 2];

    return Semantics(
      // Localised label received from parent — no hardcoded French string.
      // liveRegion: true ensures VoiceOver / TalkBack reads this on appearance.
      label: widget.label,
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: displayIndices.map((i) {
          return AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, __) {
              return Transform.translate(
                offset: Offset(0, _offsets[i].value),
                child: Opacity(
                  opacity: _opacities[i].value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingXs),
                    width: _kDotSize,
                    height: _kDotSize,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

