// lib/screens/home/widgets/image_search_sheet.dart

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/search_intent.dart';
import '../../../providers/home_search_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/sheet_chrome.dart';
import 'search_result_card.dart';

// ── File-local dimension tokens ───────────────────────────────────────────────
// [S1 FIX]: extracted from magic numbers scattered in the widget tree.
// _kPickButtonH replaces bare `height: 80` in _PickButton.
// _kPreviewH replaces bare `height: 180` in _ImagePreview and the dependent
// scan-line calculation `_scan.value * 160` which is now derived from the
// token: `_scan.value * (_kPreviewH - 20)` — the 20dp offset is the scan
// line's own height clearance so it never exits the clipped container bounds.
const double _kPickButtonH = 80.0;
const double _kPreviewH    = 180.0;

// ============================================================================
// IMAGE SEARCH SHEET
// ============================================================================

class ImageSearchSheet extends StatelessWidget {
  const ImageSearchSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => const ImageSearchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) => const _ImageSheetBody();
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ImageSheetBody extends ConsumerStatefulWidget {
  const _ImageSheetBody();

  @override
  ConsumerState<_ImageSheetBody> createState() => _ImageSheetBodyState();
}

class _ImageSheetBodyState extends ConsumerState<_ImageSheetBody> {
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  String?    _mime;

  void _reset() {
    ref.read(homeSearchControllerProvider.notifier).reset();
    setState(() {
      _imageBytes = null;
      _mime       = null;
    });
  }

  void _analyse() {
    if (_imageBytes == null) return;
    ref.read(homeSearchControllerProvider.notifier).submitSearch(
      '',
      imageBytes: _imageBytes,
      mime:       _mime,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source:       source,
        imageQuality: 80,
        maxWidth:     1024,
        maxHeight:    1024,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final mime  = picked.mimeType ?? 'image/jpeg';
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _mime       = mime;
      });
      _analyse();
    } catch (_) {
      // Picker dismissed or failed — user can retry
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final accent      = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    // [C1 FIX]: resolve onPrimary from theme — used for camera icon in header circle.
    final onPrimary   = Theme.of(context).colorScheme.onPrimary;
    final searchState = ref.watch(homeSearchControllerProvider);
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
          padding: const EdgeInsets.all(AppConstants.paddingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ────────────────────────────────────────────────────
              const SheetHandle(),
              const SizedBox(height: AppConstants.spacingMd),

              // ── Header ────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width:  AppConstants.iconContainerSm,   // 28dp — token
                    height: AppConstants.iconContainerSm,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: accent),
                    child: Center(
                      // [C1 FIX]: was Colors.white — hardcoded primitive.
                      // Replaced with colorScheme.onPrimary — semantically
                      // correct: icon contrasting with the accent fill.
                      // Reference: same fix already applied in ai_search_sheet.dart.
                      child: Icon(AppIcons.camera, size: 14, color: onPrimary),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      context.tr('home.image_search_title'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SheetCloseButton(
                    semanticsLabel: context.tr('common.close'),
                    onTap: () {
                      _reset();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Source picker (no image yet) ──────────────────────────────
              if (_imageBytes == null && !isLoading && !hasResult) ...[
                // [C2 FIX]: was raw TextStyle(fontSize: fontSizeSm, color: ...).
                // Replaced with textTheme.bodySmall?.copyWith(...).
                Text(
                  context.tr('home.image_search_hint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingLg),
                Row(
                  children: [
                    Expanded(
                      child: _PickButton(
                        icon:   AppIcons.camera,
                        label:  context.tr('home.image_pick_camera'),
                        isDark: isDark,
                        onTap:  () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: _PickButton(
                        icon:   AppIcons.gallery,
                        label:  context.tr('home.image_pick_gallery'),
                        isDark: isDark,
                        onTap:  () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Image preview ─────────────────────────────────────────────
              if (_imageBytes != null) ...[
                _ImagePreview(
                  imageBytes: _imageBytes!,
                  isLoading:  isLoading,
                  accent:     accent,
                ),
                const SizedBox(height: AppConstants.spacingMd),
              ],

              // ── Analysing label ───────────────────────────────────────────
              // [C2 FIX]: was raw TextStyle(fontSize: fontSizeSm, fontWeight: ..., color: ...).
              // Replaced with textTheme.bodySmall?.copyWith(...).
              if (isLoading)
                Text(
                  context.tr('home.image_analysing'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color:      accent,
                      ),
                ),

              // ── Error ──────────────────────────────────────────────────────
              if (hasError) ...[
                // [C2 FIX]: was raw TextStyle(fontSize: fontSizeSm, color: ...).
                // Replaced with textTheme.bodySmall?.copyWith(...).
                Text(
                  context.tr('home.search_error'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.darkError : AppTheme.lightError,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reset,
                        icon:  const Icon(AppIcons.camera, size: 16),
                        label: Text(context.tr('home.image_change')),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _imageBytes != null ? _analyse : null,
                        icon:  const Icon(AppIcons.ai, size: 16),
                        label: Text(context.tr('home.image_retry')),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Result card (merged SearchResultCard, inline style) ────────
              if (hasResult && intent != null && !isLoading) ...[
                SearchResultCard(
                  intent:       intent,
                  isDark:       isDark,
                  showTopLabel: false,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reset,
                        icon:  const Icon(AppIcons.camera, size: 16),
                        label: Text(context.tr('home.image_change')),
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
                        child: Text(
                            context.tr('home.ai_search_see_workers')),
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

// ── Image preview with scanning line ─────────────────────────────────────────

class _ImagePreview extends StatefulWidget {
  final Uint8List imageBytes;
  final bool      isLoading;
  final Color     accent;

  const _ImagePreview({
    required this.imageBytes,
    required this.isLoading,
    required this.accent,
  });

  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scan;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _scan = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      child: SizedBox(
        // [S1 FIX]: was bare `height: 180` — magic number.
        // Replaced with _kPreviewH (file-local const token = 180.0).
        height: _kPreviewH,
        width:  double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(widget.imageBytes, fit: BoxFit.cover),
            if (widget.isLoading) ...[
              const ColoredBox(color: AppTheme.overlayDark),
              AnimatedBuilder(
                animation: _scan,
                builder:   (_, __) => Positioned(
                  // [S1 FIX]: was `_scan.value * 160` — the literal 160 was
                  // a hand-computed approximation of (180 - 20) with no link
                  // to the container height token. Derived from _kPreviewH
                  // so the scan line stays within bounds if the height token
                  // is ever updated: (_kPreviewH - 20) = 160 currently.
                  top:   _scan.value * (_kPreviewH - 20),
                  left:  0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          widget.accent.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Icon(AppIcons.ai,
                    size: 28, color: widget.accent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Pick source button ────────────────────────────────────────────────────────

class _PickButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         isDark;
  final VoidCallback onTap;

  const _PickButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:  label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // [S1 FIX]: was bare `height: 80` — magic number.
          // Replaced with _kPickButtonH (file-local const token = 80.0).
          height: _kPickButtonH,
          decoration: BoxDecoration(
            color:        isDark
                ? AppTheme.darkSurface
                : AppTheme.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size:  24,
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText),
              const SizedBox(height: AppConstants.spacingXs),
              // [C2 FIX]: was raw TextStyle(fontSize: fontSizeSm, color: ...).
              // Replaced with textTheme.bodySmall?.copyWith(...).
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
