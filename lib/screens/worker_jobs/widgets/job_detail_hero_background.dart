// lib/screens/worker_jobs/widgets/job_detail_hero_background.dart

import 'package:flutter/material.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

class JobDetailHeroBackground extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool  isDark;
  final Color accentColor;

  const JobDetailHeroBackground({
    super.key,
    required this.job,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final serviceColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [
            serviceColor.withOpacity(isDark ? 0.3 : 0.15),
            isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background service icon (watermark)
          Positioned(
            right: -20,
            top:   -10,
            child: Opacity(
              opacity: isDark ? 0.07 : 0.05,
              child: Icon(
                AppTheme.getProfessionIcon(job.serviceType),
                size:  180,
                color: serviceColor,
              ),
            ),
          ),

          // Gradient fade for title legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:  Alignment.topCenter,
                  end:    Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (isDark ? AppTheme.darkSurface : AppTheme.lightSurface)
                        .withOpacity(0.9),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),

          // ID badge
          Positioned(
            top:   16,
            right: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#${job.id.substring(0, job.id.length.clamp(0, 8)).toUpperCase()}',
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize:   AppConstants.fontSizeXxs,
                    // [TOKEN FIX]: was raw 'monospace' string literal.
                    fontFamily: AppConstants.monoFontFamily,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
