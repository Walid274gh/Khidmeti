// lib/screens/onboarding/onboarding_screen.dart
//
// First-launch onboarding — 3 slides, animated dot indicator, language/theme
// pickers. Persists completion via OnboardingController.
//
// Design: Midnight Indigo v2 — full-bleed gradient background, hero typography,
// illustrated icons (Material), smooth spring-curve page transitions.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/onboarding_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import 'widgets/language_picker_pill.dart';
import 'widgets/theme_toggle_pill.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model — slide content is pure data, no widget coupling.
// ─────────────────────────────────────────────────────────────────────────────

class _SlideData {
  final IconData   icon;
  final String     titleKey;
  final String     subtitleKey;
  final Color      iconColor;

  const _SlideData({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.iconColor,
  });
}

const List<_SlideData> _kSlides = [
  _SlideData(
    icon:        Icons.search_rounded,
    titleKey:    'onboarding.slide1_title',
    subtitleKey: 'onboarding.slide1_subtitle',
    iconColor:   AppTheme.darkAccent,
  ),
  _SlideData(
    icon:        Icons.bolt_rounded,
    titleKey:    'onboarding.slide2_title',
    subtitleKey: 'onboarding.slide2_subtitle',
    iconColor:   Color(0xFF8B5CF6),
  ),
  _SlideData(
    icon:        Icons.verified_user_rounded,
    titleKey:    'onboarding.slide3_title',
    subtitleKey: 'onboarding.slide3_subtitle',
    iconColor:   Color(0xFF10B981),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {

  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _heroController;
  late final Animation<double>    _heroFade;
  late final Animation<Offset>    _heroSlide;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    _heroFade  = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic));

    _heroController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _heroController
      ..reset()
      ..forward();
  }

  Future<void> _next() async {
    HapticFeedback.selectionClick();
    if (_currentPage < _kSlides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve:    Curves.easeOutCubic,
      );
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await ref.read(onboardingControllerProvider.notifier).markDone();
    if (mounted) context.go(AppRoutes.phoneAuth);
  }

  Future<void> _skip() async {
    HapticFeedback.lightImpact();
    await _finish();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final theme   = Theme.of(context);
    final isLast  = _currentPage == _kSlides.length - 1;
    final accent  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: Stack(
          children: [
            // ── Background gradient ──────────────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center:  const Alignment(0, -1.2),
                    radius:  1.2,
                    colors:  [
                      accent.withOpacity(isDark ? 0.20 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── SafeArea content ─────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Top bar: skip left, pills right
                  _TopBar(
                    isDark:  isDark,
                    onSkip:  isLast ? null : _skip,
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // Page view
                  Expanded(
                    child: PageView.builder(
                      controller:    _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount:     _kSlides.length,
                      itemBuilder:   (_, index) => _SlidePage(
                        data:        _kSlides[index],
                        isDark:      isDark,
                        heroFade:    _heroFade,
                        heroSlide:   _heroSlide,
                        isActive:    index == _currentPage,
                      ),
                    ),
                  ),

                  // Bottom: dot indicator + CTA
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.paddingLg,
                      AppConstants.spacingMd,
                      AppConstants.paddingLg,
                      AppConstants.spacingLg,
                    ),
                    child: Column(
                      children: [
                        // Dot indicator
                        _DotIndicator(
                          count:   _kSlides.length,
                          current: _currentPage,
                          accent:  accent,
                          isDark:  isDark,
                        ),

                        const SizedBox(height: AppConstants.spacingLg),

                        // CTA button
                        _OnboardingButton(
                          isDark: isDark,
                          label:  isLast
                              ? context.tr('onboarding.get_started')
                              : context.tr('onboarding.next'),
                          onTap: _next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar — Skip left, Language + Theme right
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool        isDark;
  final VoidCallback? onSkip;

  const _TopBar({required this.isDark, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLg,
        vertical:   AppConstants.paddingMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Skip
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity:  onSkip != null ? 1.0 : 0.0,
            child: Semantics(
              button: true,
              label:  MaterialLocalizations.of(context).cancelButtonLabel,
              child: GestureDetector(
                onTap: onSkip,
                child: Container(
                  height: AppConstants.buttonHeightMd,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMd,
                  ),
                  child: Center(
                    child: Text(
                      context.tr('onboarding.skip'),
                      style: TextStyle(
                        fontSize:   AppConstants.fontSizeSm,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right pills
          Row(
            children: [
              const LanguagePickerPill(),
              const SizedBox(width: AppConstants.spacingSm),
              const ThemeTogglePill(),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide page
// ─────────────────────────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _SlideData        data;
  final bool              isDark;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final bool              isActive;

  const _SlidePage({
    required this.data,
    required this.isDark,
    required this.heroFade,
    required this.heroSlide,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingXl,
      ),
      child: FadeTransition(
        opacity: heroFade,
        child: SlideTransition(
          position: heroSlide,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon illustration
              _IconIllustration(
                icon:     data.icon,
                color:    data.iconColor,
                isDark:   isDark,
              ),

              const SizedBox(height: AppConstants.spacingXl),

              // Title
              Semantics(
                header: true,
                child: Text(
                  context.tr(data.titleKey),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight:    FontWeight.w700,
                    letterSpacing: -0.5,
                    height:        1.2,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // Subtitle
              Text(
                context.tr(data.subtitleKey),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:  isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon illustration — 120dp orb
// ─────────────────────────────────────────────────────────────────────────────

class _IconIllustration extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final bool     isDark;

  const _IconIllustration({
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width:  160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(isDark ? 0.08 : 0.06),
          ),
        ),
        // Inner ring
        Container(
          width:  120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(isDark ? 0.15 : 0.10),
          ),
        ),
        // Core
        Container(
          width:  84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(isDark ? 0.22 : 0.15),
            boxShadow: [
              BoxShadow(
                color:      color.withOpacity(0.30),
                blurRadius: 32,
                offset:     const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            size:  40,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot indicator
// ─────────────────────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int   count;
  final int   current;
  final Color accent;
  final bool  isDark;

  const _DotIndicator({
    required this.count,
    required this.current,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Slide ${current + 1} of $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (index) {
          final isActive = index == current;
          return AnimatedContainer(
            duration:  AppConstants.animDurationMicro,
            curve:     Curves.easeOutCubic,
            margin:    const EdgeInsets.symmetric(horizontal: 3),
            width:     isActive ? 24 : 8,
            height:    8,
            decoration: BoxDecoration(
              color:        isActive
                  ? accent
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA button
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingButton extends StatelessWidget {
  final bool         isDark;
  final String       label;
  final VoidCallback onTap;

  const _OnboardingButton({
    required this.isDark,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Semantics(
      button: true,
      label:  label,
      child: SizedBox(
        height: AppConstants.buttonHeight,
        width:  double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation:       0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize:   AppConstants.buttonFontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
