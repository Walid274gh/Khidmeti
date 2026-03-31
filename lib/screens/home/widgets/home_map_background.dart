// lib/screens/home/widgets/home_map_background.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../providers/home_controller.dart';
import '../../../utils/app_config.dart';
import '../../../utils/constants.dart';
import 'pulsing_location_dot.dart';
import 'worker_map_marker.dart';

// ============================================================================
// HOME MAP BACKGROUND
// ============================================================================

class HomeMapBackground extends ConsumerStatefulWidget {
  const HomeMapBackground({super.key});

  @override
  ConsumerState<HomeMapBackground> createState() => _HomeMapBackgroundState();
}

class _HomeMapBackgroundState extends ConsumerState<HomeMapBackground> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark          = Theme.of(context).brightness == Brightness.dark;
    final homeState       = ref.watch(homeControllerProvider);
    final isFullscreen    = homeState.isMapFullscreen;
    final userLocation    = homeState.userLocation;
    final filteredWorkers = homeState.filteredWorkers;
    final bestWorkerId    = homeState.bestWorkerId;

    // Fly to user location once it resolves
    ref.listen<LatLng?>(
      homeControllerProvider.select((s) => s.userLocation),
      (prev, next) {
        if (next != null && next != prev) {
          _mapController.move(next, AppConstants.defaultZoom + 1);
        }
      },
    );

    // MapTiler tiles — professional quality, no API key in source code.
    // Key is read at runtime from Firebase Remote Config via AppConfig.
    // dark  → Streets v2 Dark (blue-navy, Indigo-compatible)
    // light → Streets v2 (clean white, sharp labels)
    final mapKey  = AppConfig.maptilerApiKey;
    final tileUrl = isDark
        ? 'https://api.maptiler.com/maps/streets-v2-dark/256/{z}/{x}/{y}{r}.png?key=$mapKey'
        : 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}{r}.png?key=$mapKey';

    // Fix: filter workers that have valid coordinates before building markers.
    // Previously w.latitude! / w.longitude! would crash on null values.
    final validWorkers = filteredWorkers
        .where((w) => w.latitude != null && w.longitude != null)
        .toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userLocation ?? AppConstants.cityCenters['alger']!,
        initialZoom:   AppConstants.defaultZoom,
        minZoom:       AppConstants.minZoom,
        maxZoom:       AppConstants.maxZoom,
        interactionOptions: InteractionOptions(
          flags: isFullscreen
              ? InteractiveFlag.all
              : InteractiveFlag.none,
        ),
      ),
      children: [
        // Tile layer
        TileLayer(
          urlTemplate:          tileUrl,
          userAgentPackageName: 'com.khidmeti',
          maxZoom:              20,
          retinaMode:
              MediaQuery.of(context).devicePixelRatio > 1.0,
        ),

        // User location marker
        if (userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point:  userLocation,
                width:  28,
                height: 28,
                child:  const PulsingLocationDot(),
              ),
            ],
          ),

        // Worker markers (fullscreen only — safe coordinates guaranteed)
        if (isFullscreen && validWorkers.isNotEmpty)
          MarkerLayer(
            markers: validWorkers
                .map(
                  (w) => Marker(
                    point:  LatLng(w.latitude!, w.longitude!),
                    width:  w.id == bestWorkerId ? 58 : 50,
                    height: w.id == bestWorkerId ? 68 : 58,
                    child:  WorkerMapMarker(
                      worker:   w,
                      isBest:   w.id == bestWorkerId,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

