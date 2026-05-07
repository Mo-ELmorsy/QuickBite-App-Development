import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteInfo {
  final List<LatLng> points;
  final String distanceText;
  final String durationText;
  final int distanceValueMeters;
  final int durationValueSeconds;

  const RouteInfo({
    required this.points,
    required this.distanceText,
    required this.durationText,
    required this.distanceValueMeters,
    required this.durationValueSeconds,
  });

  factory RouteInfo.empty() {
    return const RouteInfo(
      points: [],
      distanceText: '',
      durationText: '',
      distanceValueMeters: 0,
      durationValueSeconds: 0,
    );
  }
}
