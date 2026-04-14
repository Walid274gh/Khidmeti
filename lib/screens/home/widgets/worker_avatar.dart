// lib/screens/home/widgets/worker_avatar.dart

import 'package:flutter/material.dart';

import '../../../models/worker_model.dart';
import '../../../utils/app_config.dart';
import '../../../utils/constants.dart';
import '../../../utils/media_path_helper.dart';

// ============================================================================
// WORKER AVATAR
//
// [UI-FIX SIZE]: was 62×62dp — off 8dp grid.
// Updated to 64×64dp (8dp grid canonical size).
//
// [MANUAL FIX W6]: icon size was 28dp (_kIconSize = 28.0) — undocumented and
// off the 8dp icon grid (between iconSizeMd=24 and iconSizeLg=32).
// Aligned to AppConstants.iconSizeMd (24dp): on-grid, proportional at ~37%
// of the 64dp avatar container, and consistent with icon scale system-wide.
//
// [MEDIA FIX]: profileImageUrl est un storedPath ("bucket/uid/file.jpg").
// Converti en URL proxy via MediaPathHelper.toUrl() avant Image.network.
// ============================================================================

const double _kAvatarSize = 64.0;

class WorkerAvatar extends StatelessWidget {
  final WorkerModel worker;
  final Color       color;

  const WorkerAvatar({super.key, required this.worker, required this.color});

  @override
  Widget build(BuildContext context) {
    // Convertit storedPath ou ancienne URL en URL proxy complète
    final displayUrl = worker.profileImageUrl != null
        ? MediaPathHelper.toUrl(
            worker.profileImageUrl,
            apiBaseUrl: AppConfig.apiBaseUrl,
          )
        : null;

    return Container(
      width:  _kAvatarSize,
      height: _kAvatarSize,
      decoration: BoxDecoration(
        shape:  BoxShape.circle,
        color:  color.withOpacity(0.12),
        border: Border.all(color: color, width: 2),
      ),
      child: displayUrl != null && displayUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                displayUrl,
                fit:          BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  AppIcons.person,
                  color: color,
                  size:  AppConstants.iconSizeMd,
                ),
              ),
            )
          : Icon(AppIcons.person, color: color, size: AppConstants.iconSizeMd),
    );
  }
}
