import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeoRestrictionService {
  // Coordonnées approximatives de la RDC (polygone simplifié)
  static const List<LatLng> _rdcBoundary = [
    LatLng(5.392, 12.191), // Nord-ouest
    LatLng(5.392, 31.306), // Nord-est
    LatLng(-13.459, 31.306), // Sud-est
    LatLng(-13.459, 12.191), // Sud-ouest
  ];

  // Zone de couverture principale (Kinshasa et environs) - Élargie
  static const List<LatLng> _kinshasaZone = [
    LatLng(-4.241, 15.166), // Nord-ouest Kinshasa (élargi)
    LatLng(-4.241, 15.466), // Nord-est Kinshasa (élargi)
    LatLng(-4.641, 15.466), // Sud-est Kinshasa (élargi)
    LatLng(-4.641, 15.166), // Sud-ouest Kinshasa (élargi)
  ];

  // Vérifier si une position est dans la RDC
  static bool isInRDC(LatLng position) {
    return _isPointInPolygon(position, _rdcBoundary);
  }

  // Vérifier si une position est dans la zone de livraison (Kinshasa)
  static bool isInDeliveryZone(LatLng position) {
    return _isPointInPolygon(position, _kinshasaZone);
  }

  // Vérifier si une adresse est dans la zone de couverture
  static bool isAddressInServiceArea(String address) {
    // Pour l'instant, on vérifie par mots-clés
    final lowerAddress = address.toLowerCase();
    
    // Mots-clés pour la RDC
    final rdcKeywords = [
      'rdc', 'république démocratique du congo', 'congo', 'kinshasa',
      'lubumbashi', 'mbuji-mayi', 'kananga', 'kisangani', 'bukavu',
      'matadi', 'boma', 'kolwezi', 'likasi', 'kalemie', 'goma'
    ];

    return rdcKeywords.any((keyword) => lowerAddress.contains(keyword));
  }

  // Vérifier si une adresse est dans Kinshasa (plus permissive)
  static bool isAddressInKinshasa(String address) {
    final lowerAddress = address.toLowerCase();
    
    // Mots-clés spécifiques à Kinshasa
    final kinshasaKeywords = [
      'kinshasa', 'kin', 'upn', 'gombe', 'limete', 'masina', 'ngaliema',
      'kalamu', 'bandalungwa', 'barumbu', 'bumbu', 'kasa-vubu', 'kimbanseke',
      'kisenso', 'lemba', 'maluku', 'mont-ngafula', 'n\'sele', 'ngaba',
      'ngiri-ngiri', 'nsele', 'selembao', 'matete', 'ndjili', 'masina',
      'binza', 'ngaliema', 'selembao', 'bumbu', 'kalamu', 'limete'
    ];

    return kinshasaKeywords.any((keyword) => lowerAddress.contains(keyword));
  }

  // Obtenir le message d'erreur pour une zone non couverte
  static String getOutOfServiceMessage(LatLng position) {
    if (!isInRDC(position)) {
      return 'Désolé, notre service n\'est pas disponible en dehors de la RDC.';
    } else if (!isInDeliveryZone(position)) {
      return 'Désolé, notre service de livraison n\'est disponible qu\'à Kinshasa pour le moment.';
    }
    return 'Zone non couverte par notre service.';
  }

  // Obtenir les zones de couverture actuelles
  static Map<String, List<LatLng>> getServiceAreas() {
    return {
      'Kinshasa': _kinshasaZone,
      'RDC': _rdcBoundary,
    };
  }

  // Algorithme point-in-polygon (Ray casting algorithm)
  static bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * 
           (point.latitude - polygon[i].latitude) / 
           (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  // Calculer la distance entre deux points (formule de Haversine)
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    double lat1Rad = point1.latitude * (3.14159265359 / 180);
    double lat2Rad = point2.latitude * (3.14159265359 / 180);
    double deltaLat = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    double deltaLon = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
               cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Vérifier si une distance est dans les limites de livraison
  static bool isWithinDeliveryDistance(double distanceKm) {
    const double maxDeliveryDistance = 50.0; // 50 km max
    return distanceKm <= maxDeliveryDistance;
  }

  // Validation intelligente pour les adresses de Kinshasa
  static bool validateKinshasaAddress(String address, LatLng? position) {
    // Si on a une position GPS, vérifier d'abord la zone géographique
    if (position != null) {
      if (isInDeliveryZone(position)) {
        return true;
      }
    }
    
    // Sinon, vérifier par mots-clés
    return isAddressInKinshasa(address);
  }

  // Obtenir un message d'erreur plus informatif
  static String getAddressValidationMessage(String address, LatLng? position) {
    if (position != null && !isInRDC(position)) {
      return 'Désolé, notre service n\'est pas disponible en dehors de la RDC.';
    }
    
    if (position != null && !isInDeliveryZone(position) && !isAddressInKinshasa(address)) {
      return 'Désolé, notre service de livraison n\'est disponible qu\'à Kinshasa pour le moment.';
    }
    
    if (isAddressInKinshasa(address)) {
      return 'Adresse acceptée - Zone de livraison Kinshasa';
    }
    
    return 'Veuillez vérifier que l\'adresse est bien à Kinshasa.';
  }

  // Obtenir le centre de Kinshasa
  static LatLng getKinshasaCenter() {
    return const LatLng(-4.441, 15.266);
  }

  // Obtenir le centre de la RDC
  static LatLng getRDCCenter() {
    return const LatLng(-4.038, 21.759);
  }
}
