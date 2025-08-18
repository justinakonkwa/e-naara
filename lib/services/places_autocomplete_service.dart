import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ecommerce/services/geo_restriction_service.dart';

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting['main_text'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
    );
  }
}

class PlaceDetails {
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? streetNumber;
  final String? route;
  final String? locality;
  final String? administrativeArea;
  final String? country;

  PlaceDetails({
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    this.streetNumber,
    this.route,
    this.locality,
    this.administrativeArea,
    this.country,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final result = json['result'] ?? {};
    final geometry = result['geometry'] ?? {};
    final location = geometry['location'] ?? {};
    final addressComponents = result['address_components'] ?? [];

    String? streetNumber;
    String? route;
    String? locality;
    String? administrativeArea;
    String? country;

    for (var component in addressComponents) {
      final types = List<String>.from(component['types'] ?? []);
      final longName = component['long_name'] ?? '';

      if (types.contains('street_number')) {
        streetNumber = longName;
      } else if (types.contains('route')) {
        route = longName;
      } else if (types.contains('locality')) {
        locality = longName;
      } else if (types.contains('administrative_area_level_1')) {
        administrativeArea = longName;
      } else if (types.contains('country')) {
        country = longName;
      }
    }

    return PlaceDetails(
      formattedAddress: result['formatted_address'] ?? '',
      latitude: location['lat']?.toDouble(),
      longitude: location['lng']?.toDouble(),
      streetNumber: streetNumber,
      route: route,
      locality: locality,
      administrativeArea: administrativeArea,
      country: country,
    );
  }
}

class PlacesAutocompleteService {
  static const String _apiKey = 'AIzaSyANflIly_89plAggq-v-vqpKkOlWTqdHys';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  // Obtenir des suggestions d'adresses
  static Future<List<PlacePrediction>> getPlacePredictions(String input) async {
    if (input.isEmpty) return [];

    try {
      // Restreindre la recherche à la RDC
      final rdcCenter = GeoRestrictionService.getRDCCenter();
      
      final url = Uri.parse(
        '$_baseUrl/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=$_apiKey'
        '&language=fr'
        '&components=country:cd' // Restreindre à la RDC (code pays: cd)
        '&location=${rdcCenter.latitude},${rdcCenter.longitude}'
        '&radius=1000000' // 1000 km autour du centre de la RDC
        '&types=address'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List?;
        
        if (predictions != null) {
          return predictions
              .map((prediction) => PlacePrediction.fromJson(prediction))
              .where((prediction) => _isValidForRDC(prediction))
              .toList();
        }
      }
    } catch (e) {
      print('[PLACES] Erreur lors de la recherche d\'adresses: $e');
    }

    return [];
  }

  // Obtenir les détails d'un lieu
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/place/details/json'
        '?place_id=$placeId'
        '&key=$_apiKey'
        '&language=fr'
        '&fields=formatted_address,geometry,address_components'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        
        if (result != null) {
          return PlaceDetails.fromJson(data);
        }
      }
    } catch (e) {
      print('[PLACES] Erreur lors de la récupération des détails: $e');
    }

    return null;
  }

  // Filtrer les résultats pour la RDC
  static bool _isValidForRDC(PlacePrediction prediction) {
    final description = prediction.description.toLowerCase();
    
    // Mots-clés pour la RDC
    final rdcKeywords = [
      'rdc', 'république démocratique du congo', 'congo', 'kinshasa',
      'lubumbashi', 'mbuji-mayi', 'kananga', 'kisangani', 'bukavu',
      'matadi', 'boma', 'kolwezi', 'likasi', 'kalemie', 'goma',
      'rd congo', 'drc', 'democratic republic of congo'
    ];

    return rdcKeywords.any((keyword) => description.contains(keyword));
  }

  // Recherche locale pour les adresses communes en RDC
  static List<String> getLocalSuggestions(String input) {
    if (input.isEmpty) return [];

    final localAddresses = [
      // Kinshasa - Adresses populaires
      'UPN, Kinshasa',
      'Gombe, Kinshasa',
      'Limete, Kinshasa',
      'Masina, Kinshasa',
      'Ngaliema, Kinshasa',
      'Kalamu, Kinshasa',
      'Bandalungwa, Kinshasa',
      'Barumbu, Kinshasa',
      'Bumbu, Kinshasa',
      'Kasa-Vubu, Kinshasa',
      'Kimbanseke, Kinshasa',
      'Kisenso, Kinshasa',
      'Lemba, Kinshasa',
      'Maluku, Kinshasa',
      'Mont-Ngafula, Kinshasa',
      'N\'Sele, Kinshasa',
      'Ngaba, Kinshasa',
      'Ngiri-Ngiri, Kinshasa',
      'Nsele, Kinshasa',
      'Selembao, Kinshasa',
      'Matete, Kinshasa',
      'Ndjili, Kinshasa',
      'Binza, Kinshasa',
      'Avenue du Commerce, Gombe',
      'Avenue des Aviateurs, Gombe',
      'Boulevard du 30 Juin, Gombe',
      'Place de l\'Indépendance, Gombe',
      'Marché Central, Gombe',
      'Université Pédagogique Nationale, Kinshasa',
      'Campus UPN, Kinshasa',
      'Aéroport N\'Djili, Kinshasa',
      'Gare Centrale, Kinshasa',
      'Port de Kinshasa, Kinshasa',
      'Marché de la Liberté, Limete',
      'Marché Central, Masina',
      'Marché de Ngaba, Kinshasa',
      'Marché de Matete, Kinshasa',
      // Autres villes RDC
      'Lubumbashi, Centre-ville',
      'Lubumbashi, Katuba',
      'Lubumbashi, Kamalondo',
      'Lubumbashi, Kenya',
      'Lubumbashi, Ruashi',
      'Goma, Centre-ville',
      'Bukavu, Centre-ville',
      'Kisangani, Centre-ville',
      'Matadi, Centre-ville',
    ];

    final lowerInput = input.toLowerCase();
    return localAddresses
        .where((address) => address.toLowerCase().contains(lowerInput))
        .take(10)
        .toList();
  }

  // Formater une adresse pour l'affichage
  static String formatAddressForDisplay(PlaceDetails details) {
    final parts = <String>[];
    
    if (details.streetNumber != null) parts.add(details.streetNumber!);
    if (details.route != null) parts.add(details.route!);
    if (details.locality != null) parts.add(details.locality!);
    if (details.administrativeArea != null) parts.add(details.administrativeArea!);
    
    return parts.join(', ');
  }

  // Vérifier si une adresse est dans la zone de livraison
  static bool isAddressInDeliveryZone(PlaceDetails details) {
    if (details.latitude == null || details.longitude == null) return false;
    
    final position = LatLng(details.latitude!, details.longitude!);
    return GeoRestrictionService.isInDeliveryZone(position);
  }
}
