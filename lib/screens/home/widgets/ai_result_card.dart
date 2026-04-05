// lib/screens/home/widgets/ai_result_card.dart
//
// Thin wrapper around SearchResultCard that preserves the existing public API
// used in ai_search_sheet.dart. All display logic now lives in search_result_card.dart.

import 'package:flutter/material.dart';

import '../../../models/search_intent.dart';
import 'search_result_card.dart';

class AiResultCard extends StatelessWidget {
  final SearchIntent intent;
  final bool         isDark;

  const AiResultCard({
    super.key,
    required this.intent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SearchResultCard(
      intent:       intent,
      isDark:       isDark,
      showTopLabel: true,
    );
  }
}
