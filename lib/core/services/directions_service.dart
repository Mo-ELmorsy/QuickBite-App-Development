import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import '../models/route_info.dart';

class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  final String _apiKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  Future<RouteInfo?> getRoutePolyline({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (_apiKey.isEmpty) return null;

    try {
      final url = '$_baseUrl?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if ((data['routes'] as List).isEmpty) return null;

        final route = data['routes'][0];
        final leg = route['legs'][0];
        
        // Use the static method decodePolyline
        final polylinePoints = PolylinePoints.decodePolyline(route['overview_polyline']['points']);
        final List<LatLng> points = polylinePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

        return RouteInfo(
          points: points,
          distanceText: leg['distance']['text'],
          durationText: leg['duration']['text'],
          distanceValueMeters: leg['distance']['value'],
          durationValueSeconds: leg['duration']['value'],
        );
      }
    } catch (e) {
      debugPrint('Directions Error: $e');
    }
    return null;
  }
}
