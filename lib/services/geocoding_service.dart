import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodingService {
  static const String _apiKey = 'AIzaSyANflIly_89plAggq-v-vqpKkOlWTqdHys';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  /// Convertit une adresse en coordonnées GPS
  static Future<LatLng?> geocodeAddress(String address) async {
    try {
      final url = Uri.parse('$_baseUrl?address=${Uri.encodeComponent(address)}&key=$_apiKey');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ [GEOCODING] Erreur géocodage: $e');
      return null;
    }
  }

  /// Convertit des coordonnées GPS en adresse
  static Future<String?> reverseGeocode(LatLng position) async {
    try {
      final url = Uri.parse('$_baseUrl?latlng=${position.latitude},${position.longitude}&key=$_apiKey');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
      
      return null;
    } catch (e) {
      print('❌ [GEOCODING] Erreur géocodage inverse: $e');
      return null;
    }
  }

  /// Valide si une adresse est géocodable
  static Future<bool> isAddressValid(String address) async {
    final coordinates = await geocodeAddress(address);
    return coordinates != null;
  }

  /// Obtient des suggestions d'adresses basées sur une saisie partielle
  static Future<List<String>> getAddressSuggestions(String partialAddress) async {
    try {
      final url = Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(partialAddress)}&key=$_apiKey&types=address');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((prediction) => prediction['description'] as String)
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      print('❌ [GEOCODING] Erreur suggestions: $e');
      return [];
    }
  }
}


