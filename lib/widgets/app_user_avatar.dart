// lib/widgets/app_user_avatar.dart

import 'package:flutter/material.dart';

class AppUserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String  name;
  final double  radius;
  final Color?  borderColor;
  final double  borderWidth;

  const AppUserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius      = 36,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  // ── Initials derivation — handles single-word names and empty strings ──────

  String get _initials {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  // ── Cache size: 2× radius at 3× device pixel ratio (reasonable upper bound) ─

  int get _cacheSize => (radius * 2 * 3).ceil();

  @override
  Widget build(BuildContext context) {
    final ringColor = borderColor ?? Colors.white.withOpacity(0.40);
    final size      = radius * 2;

    return Semantics(
      label: name.trim().isNotEmpty ? name.trim() : _initials,
      image: true,
      child: Container(
        width:  size,
        height: size,
        decoration: BoxDecoration(
          shape:  BoxShape.circle,
          border: Border.all(color: ringColor, width: borderWidth),
        ),
        child: ClipOval(
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  width:       size,
                  height:      size,
                  fit:         BoxFit.cover,
                  cacheWidth:  _cacheSize,
                  cacheHeight: _cacheSize,
                  loadingBuilder: (_, child, progress) =>
                      progress == null
                          ? child
                          : _InitialsFallback(initials: _initials, radius: radius),
                  errorBuilder: (_, __, ___) =>
                      _InitialsFallback(initials: _initials, radius: radius),
                )
              : _InitialsFallback(initials: _initials, radius: radius),
        ),
      ),
    );
  }
}

// ── Private fallback — rendered when imageUrl is null / empty / load-failed ──

class _InitialsFallback extends StatelessWidget {
  final String initials;
  final double radius;

  const _InitialsFallback({
    required this.initials,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color:     isDark
          ? Colors.white.withOpacity(0.20)
          : Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          // FIX (Engineer): was `fontSize: null` which always produced the
          // theme default (14dp) regardless of avatar size. A 28×28 avatar
          // (radius 14) got 14dp text — too large. A 128×128 avatar (radius 64)
          // also got 14dp — too small. The comment "~37% of diameter" was
          // correct in intent but never implemented.
          //
          // Fix: fontSize = radius × 0.74 ≈ 37% of the diameter.
          // Examples:
          //   radius 20  →  14.8dp   (small chip avatar)
          //   radius 36  →  26.6dp   (standard list avatar)
          //   radius 64  →  47.4dp   (profile header avatar)
          fontSize:   radius * 0.74,
          fontWeight: FontWeight.w700,
          color: isDark
              ? Colors.white
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
