// lib/screens/home/widgets/worker_avatar.dart

import 'package:flutter/material.dart';

import '../../../models/worker_model.dart';
import '../../../utils/constants.dart';

// ============================================================================
// WORKER AVATAR
// ============================================================================

class WorkerAvatar extends StatelessWidget {
  final WorkerModel worker;
  final Color       color;

  const WorkerAvatar({super.key, required this.worker, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  62,
      height: 62,
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
                    Icon(AppIcons.person, color: color, size: 30),
              ),
            )
          : Icon(AppIcons.person, color: color, size: 30),
    );
  }
}

