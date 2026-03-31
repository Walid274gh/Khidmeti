// lib/screens/worker_jobs/widgets/sticky_filter_delegate.dart

import 'package:flutter/material.dart';

class StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const StickyFilterDelegate({required this.child});

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(context, shrinkOffset, overlapsContent) => child;

  @override
  bool shouldRebuild(StickyFilterDelegate old) => old.child != child;
}
