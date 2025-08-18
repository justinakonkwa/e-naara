import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationService {
  /// Ouvre la navigation vers une destination
  static Future<bool> openNavigation({
    required LatLng destination,
    String? destinationName,
    LatLng? origin,
  }) async {
    try {
      // Construire l'URL de navigation Google Maps
      final destinationStr = destinationName ?? '${destination.latitude},${destination.longitude}';
      final originStr = origin != null ? '${origin.latitude},${origin.longitude}' : '';
      
      String url;
      if (origin != null) {
        // Navigation avec point de départ et destination
        url = 'https://www.google.com/maps/dir/$originStr/$destinationStr';
      } else {
        // Navigation vers destination (depuis la position actuelle)
        url = 'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}';
      }

      print('🗺️ [NAVIGATION] Ouverture de la navigation vers: $destinationStr');
      print('🗺️ [NAVIGATION] URL: $url');

      // Essayer d'ouvrir l'URL
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          print('✅ [NAVIGATION] Navigation ouverte avec succès');
          return true;
        } else {
          print('❌ [NAVIGATION] Échec de l\'ouverture de la navigation');
          return false;
        }
      } else {
        print('❌ [NAVIGATION] Impossible de lancer l\'URL: $url');
        return false;
      }
    } catch (e) {
      print('❌ [NAVIGATION] Erreur lors de l\'ouverture de la navigation: $e');
      return false;
    }
  }

  /// Ouvre Google Maps avec une recherche d'adresse
  static Future<bool> openMapsWithAddress(String address) async {
    try {
      final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
      final uri = Uri.parse(url);
      
      print('🗺️ [NAVIGATION] Ouverture de Google Maps pour: $address');
      print('🗺️ [NAVIGATION] URL: $url');

      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          print('✅ [NAVIGATION] Google Maps ouvert avec succès');
          return true;
        } else {
          print('❌ [NAVIGATION] Échec de l\'ouverture de Google Maps');
          return false;
        }
      } else {
        print('❌ [NAVIGATION] Impossible de lancer Google Maps');
        return false;
      }
    } catch (e) {
      print('❌ [NAVIGATION] Erreur lors de l\'ouverture de Google Maps: $e');
      return false;
    }
  }

  /// Ouvre l'application téléphone pour appeler un numéro
  static Future<bool> openPhoneCall(String phoneNumber) async {
    try {
      // Nettoyer le numéro de téléphone
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final url = 'tel:$cleanNumber';
      final uri = Uri.parse(url);
      
      print('📞 [NAVIGATION] Ouverture de l\'appel vers: $cleanNumber');

      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        final launched = await launchUrl(uri);
        
        if (launched) {
          print('✅ [NAVIGATION] Appel lancé avec succès');
          return true;
        } else {
          print('❌ [NAVIGATION] Échec de l\'ouverture de l\'appel');
          return false;
        }
      } else {
        print('❌ [NAVIGATION] Impossible de lancer l\'appel');
        return false;
      }
    } catch (e) {
      print('❌ [NAVIGATION] Erreur lors de l\'ouverture de l\'appel: $e');
      return false;
    }
  }

  /// Ouvre WhatsApp pour envoyer un message
  static Future<bool> openWhatsApp({
    required String phoneNumber,
    String? message,
  }) async {
    try {
      // Nettoyer le numéro de téléphone
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      // Ajouter l'indicatif du pays si nécessaire (RDC: +243)
      final fullNumber = cleanNumber.startsWith('243') ? cleanNumber : '243$cleanNumber';
      
      String url = 'https://wa.me/$fullNumber';
      if (message != null) {
        url += '?text=${Uri.encodeComponent(message)}';
      }
      
      final uri = Uri.parse(url);
      
      print('💬 [NAVIGATION] Ouverture de WhatsApp vers: $fullNumber');

      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          print('✅ [NAVIGATION] WhatsApp ouvert avec succès');
          return true;
        } else {
          print('❌ [NAVIGATION] Échec de l\'ouverture de WhatsApp');
          return false;
        }
      } else {
        print('❌ [NAVIGATION] Impossible de lancer WhatsApp');
        return false;
      }
    } catch (e) {
      print('❌ [NAVIGATION] Erreur lors de l\'ouverture de WhatsApp: $e');
      return false;
    }
  }

  /// Vérifie si une application peut être lancée
  static Future<bool> canLaunchNavigation() async {
    try {
      // Tester avec une URL Google Maps simple
      const testUrl = 'https://www.google.com/maps';
      final uri = Uri.parse(testUrl);
      return await canLaunchUrl(uri);
    } catch (e) {
      print('❌ [NAVIGATION] Erreur lors de la vérification: $e');
      return false;
    }
  }
}

