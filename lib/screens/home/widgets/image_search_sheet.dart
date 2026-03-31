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

// ============================================================================
// IMAGE SEARCH SHEET
//
// Camera icon in search bar → this sheet.
//
// Flow:
//   1. Sheet opens → choose gallery or camera
//   2. Image preview shown
//   3. Analysis starts IMMEDIATELY — no send button
//   4. _ImageResultCard shown → user confirms → map fullscreen
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
      // Auto-analyse immediately — no button needed
      _analyse();
    } catch (_) {
      // Picker dismissed or failed — user can retry
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final accent      = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
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
              const SizedBox(height: AppConstants.spacingMd),

              // ── Header ────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width:  28,
                    height: 28,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: accent),
                    child: const Center(
                      child: Icon(AppIcons.camera,
                          size: 14, color: Colors.white),
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
                  Semantics(
                    label:  context.tr('common.close'),
                    button: true,
                    child: GestureDetector(
                      onTap: () {
                        _reset();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width:  32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppTheme.darkSurface
                              : AppTheme.lightSurfaceVariant,
                        ),
                        child: Center(
                          child: Icon(AppIcons.close,
                              size: 16,
                              color: isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Source picker (no image yet) ──────────────────────────────
              if (_imageBytes == null && !isLoading && !hasResult) ...[
                Text(
                  context.tr('home.image_search_hint'),
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeSm,
                    color:    isDark
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
              if (isLoading)
                Text(
                  context.tr('home.image_analysing'),
                  style: TextStyle(
                    fontSize:   AppConstants.fontSizeSm,
                    fontWeight: FontWeight.w500,
                    color:      accent,
                  ),
                ),

              // ── Error ──────────────────────────────────────────────────────
              if (hasError) ...[
                Text(
                  context.tr('home.search_error'),
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeSm,
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

              // ── Result card ───────────────────────────────────────────────
              if (hasResult && intent != null && !isLoading) ...[
                _ImageResultCard(intent: intent, isDark: isDark),
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
        height: 180,
        width:  double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(widget.imageBytes, fit: BoxFit.cover),
            if (widget.isLoading) ...[
              ColoredBox(color: Colors.black.withOpacity(0.45)),
              AnimatedBuilder(
                animation: _scan,
                builder:   (_, __) => Positioned(
                  top:   _scan.value * 160,
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

// ── Image result card ─────────────────────────────────────────────────────────

class _ImageResultCard extends StatelessWidget {
  final SearchIntent intent;
  final bool         isDark;

  const _ImageResultCard({required this.intent, required this.isDark});

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
            width:  40,
            height: 40,
            decoration: BoxDecoration(
              color:  color.withOpacity(0.14),
              shape:  BoxShape.circle,
            ),
            child: Center(child: Icon(icon, size: 20, color: color)),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('home.ai_result_label'),
                  style: TextStyle(
                    fontSize:      AppConstants.fontSizeXs,
                    fontWeight:    FontWeight.w700,
                    color:         accent,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  intent.profession != null
                      ? context.tr('services.${intent.profession}')
                      : context.tr('home.filter_all'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                ),
                if (intent.problemDescription != null &&
                    intent.problemDescription!.isNotEmpty)
                  Text(
                    intent.problemDescription!,
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeXs,
                      color:    isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (intent.isUrgent)
                  Padding(
                    padding: const EdgeInsets.only(top: AppConstants.spacingXs),
                    child: Text(
                      context.tr('home.search_urgent_badge'),
                      style: TextStyle(
                        fontSize:   AppConstants.fontSizeXs,
                        fontWeight: FontWeight.w700,
                        color:      AppTheme.recordingRed,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingXs),
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
          height: 80,
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
              Text(
                label,
                style: TextStyle(
                  fontSize: AppConstants.fontSizeSm,
                  color:    isDark
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
