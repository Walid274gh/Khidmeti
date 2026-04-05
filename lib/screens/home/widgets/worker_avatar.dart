// lib/screens/home/widgets/worker_avatar.dart

import 'package:flutter/material.dart';

import '../../../models/worker_model.dart';
import '../../../utils/constants.dart';

// ============================================================================
// WORKER AVATAR
//
// [UI-FIX SIZE]: was 62×62dp — off 8dp grid.
// Updated to 64×64dp (8dp grid canonical size).
// Icon size updated from 30 → 28dp to maintain visual proportion.
// ============================================================================

// Canonical avatar size — on 8dp grid.
const double _kAvatarSize = 64.0;
const double _kIconSize   = 28.0;

class WorkerAvatar extends StatelessWidget {
  final WorkerModel worker;
  final Color       color;

  const WorkerAvatar({super.key, required this.worker, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  _kAvatarSize,
      height: _kAvatarSize,
      decoration: BoxDecoration(
        shape:  BoxShape.circle,
        color:  color.withOpacity(0.12),
        border: Border.all(color: color, width: 2),
      ),
      child: worker.profileImageUrl != null
          ? ClipOval(
              child: Image.network(
                worker.profileImageUrl!,
                fit:          BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(AppIcons.person, color: color, size: _kIconSize),
              ),
            )
          : Icon(AppIcons.person, color: color, size: _kIconSize),
    );
  }
}
