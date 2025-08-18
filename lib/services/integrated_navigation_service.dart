import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationRoute {
  final List<LatLng> points;
  final double distance; // en mètres
  final int duration; // en secondes
  final String polyline;

  NavigationRoute({
    required this.points,
    required this.distance,
    required this.duration,
    required this.polyline,
  });
}

class IntegratedNavigationService {
  static const String _apiKey = 'AIzaSyANflIly_89plAggq-v-vqpKkOlWTqdHys';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Calculer l'itinéraire entre deux points
  static Future<NavigationRoute?> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    String? mode = 'driving', // driving, walking, bicycling, transit
  }) async {
    try {
      print('🗺️ [NAVIGATION] Calcul de l\'itinéraire: ${origin.latitude},${origin.longitude} → ${destination.latitude},${destination.longitude}');
      
      final url = Uri.parse(
        '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$mode'
        '&key=$_apiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final polyline = route['overview_polyline']['points'];
          
          // Décoder le polyline pour obtenir les points
          final points = _decodePolyline(polyline);
          
          final navigationRoute = NavigationRoute(
            points: points,
            distance: leg['distance']['value'].toDouble(),
            duration: leg['duration']['value'],
            polyline: polyline,
          );
          
          print('✅ [NAVIGATION] Itinéraire calculé: ${(navigationRoute.distance / 1000).toStringAsFixed(1)} km, ${(navigationRoute.duration / 60).round()} min');
          
          return navigationRoute;
        } else {
          print('❌ [NAVIGATION] Erreur API: ${data['status']} - ${data['error_message'] ?? 'Aucun message'}');
          return null;
        }
      } else {
        print('❌ [NAVIGATION] Erreur HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ [NAVIGATION] Erreur lors du calcul de l\'itinéraire: $e');
      return null;
    }
  }

  /// Décoder un polyline Google Maps en liste de points LatLng
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  /// Formater la distance pour l'affichage
  static String formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Formater la durée pour l'affichage
  static String formatDuration(int durationSeconds) {
    if (durationSeconds < 60) {
      return '$durationSeconds sec';
    } else if (durationSeconds < 3600) {
      return '${(durationSeconds / 60).round()} min';
    } else {
      final hours = (durationSeconds / 3600).floor();
      final minutes = ((durationSeconds % 3600) / 60).round();
      return '$hours h $minutes min';
    }
  }

  /// Calculer la distance directe entre deux points (formule de Haversine)
  static double calculateDirectDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Rayon de la Terre en mètres

    double lat1Rad = point1.latitude * (pi / 180);
    double lat2Rad = point2.latitude * (pi / 180);
    double deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
    double deltaLon = (point2.longitude - point1.longitude) * (pi / 180);

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
               cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Obtenir les instructions de navigation
  static List<String> getNavigationInstructions(Map<String, dynamic> routeData) {
    List<String> instructions = [];
    
    try {
      final routes = routeData['routes'] as List;
      if (routes.isNotEmpty) {
        final legs = routes[0]['legs'] as List;
        if (legs.isNotEmpty) {
          final steps = legs[0]['steps'] as List;
          
          for (final step in steps) {
            final instruction = step['html_instructions'] as String;
            // Nettoyer les balises HTML
            final cleanInstruction = instruction
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .replaceAll('&nbsp;', ' ')
                .trim();
            
            if (cleanInstruction.isNotEmpty) {
              instructions.add(cleanInstruction);
            }
          }
        }
      }
    } catch (e) {
      print('❌ [NAVIGATION] Erreur lors de l\'extraction des instructions: $e');
    }
    
    return instructions;
  }

  /// Calculer l'angle de direction entre deux points
  static double calculateBearing(LatLng from, LatLng to) {
    final double lat1 = from.latitude * (pi / 180);
    final double lat2 = to.latitude * (pi / 180);
    final double dLon = (to.longitude - from.longitude) * (pi / 180);

    final double y = sin(dLon) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    
    double bearing = atan2(y, x) * (180 / pi);
    
    // Normaliser entre 0 et 360
    bearing = (bearing + 360) % 360;
    
    return bearing;
  }

  /// Obtenir la direction cardinale à partir d'un angle
  static String getCardinalDirection(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'N';
    if (bearing >= 22.5 && bearing < 67.5) return 'NE';
    if (bearing >= 67.5 && bearing < 112.5) return 'E';
    if (bearing >= 112.5 && bearing < 157.5) return 'SE';
    if (bearing >= 157.5 && bearing < 202.5) return 'S';
    if (bearing >= 202.5 && bearing < 247.5) return 'SO';
    if (bearing >= 247.5 && bearing < 292.5) return 'O';
    if (bearing >= 292.5 && bearing < 337.5) return 'NO';
    return 'N';
  }
}
