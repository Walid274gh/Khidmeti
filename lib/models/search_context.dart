// lib/models/search_context.dart

import 'package:equatable/equatable.dart';

/// Contexte de recherche pour optimisation
class SearchContext extends Equatable {
  final double userLat;
  final double userLng;
  final int userWilayaCode;
  final String currentCellId;
  final double maxRadius;
  final int maxResults;
  final Set<String> searchedCellIds;
  final Set<int> searchedWilayaCodes;

  const SearchContext({
    required this.userLat,
    required this.userLng,
    required this.userWilayaCode,
    required this.currentCellId,
    this.maxRadius = 50.0,
    this.maxResults = 20,
    this.searchedCellIds = const {},
    this.searchedWilayaCodes = const {},
  });

  SearchContext copyWith({
    double? userLat,
    double? userLng,
    int? userWilayaCode,
    String? currentCellId,
    double? maxRadius,
    int? maxResults,
    Set<String>? searchedCellIds,
    Set<int>? searchedWilayaCodes,
  }) {
    return SearchContext(
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      userWilayaCode: userWilayaCode ?? this.userWilayaCode,
      currentCellId: currentCellId ?? this.currentCellId,
      maxRadius: maxRadius ?? this.maxRadius,
      maxResults: maxResults ?? this.maxResults,
      searchedCellIds: searchedCellIds ?? this.searchedCellIds,
      searchedWilayaCodes: searchedWilayaCodes ?? this.searchedWilayaCodes,
    );
  }

  @override
  List<Object?> get props => [
        userLat,
        userLng,
        userWilayaCode,
        currentCellId,
        maxRadius,
        maxResults,
        searchedCellIds,
        searchedWilayaCodes,
      ];
}
