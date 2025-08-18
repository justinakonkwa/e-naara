import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce/services/location_service.dart';

class TrackingService {
  static const String _channel = 'driver_tracking';
  
  /// Mettre à jour la position du livreur
  static Future<bool> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    int? heading,
    int? batteryLevel,
    bool isOnline = true,
  }) async {
    try {
      print('📍 [TRACKING] Mise à jour position livreur: $driverId');
      
      final response = await Supabase.instance.client
          .from('driver_locations')
          .upsert({
        'driver_id': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'battery_level': batteryLevel,
        'is_online': isOnline,
        'last_updated': DateTime.now().toIso8601String(),
      });

      print('✅ [TRACKING] Position mise à jour avec succès');
      return true;
    } catch (e) {
      print('❌ [TRACKING] Erreur mise à jour position: $e');
      return false;
    }
  }

  /// Mettre à jour la position avec un objet Position
  static Future<bool> updateDriverLocationFromPosition({
    required String driverId,
    required Position position,
    int? batteryLevel,
    bool isOnline = true,
  }) async {
    return await updateDriverLocation(
      driverId: driverId,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading.toInt(),
      batteryLevel: batteryLevel,
      isOnline: isOnline,
    );
  }

  /// Écouter les changements de position d'un livreur
  static Stream<List<Map<String, dynamic>>> watchDriverLocation(String driverId) {
    print('📍 [TRACKING] Surveillance position livreur: $driverId');
    
    return Supabase.instance.client
        .from('driver_locations')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId)
        .order('last_updated', ascending: false)
        .limit(1);
  }

  /// Obtenir la position actuelle d'un livreur
  static Future<Map<String, dynamic>?> getDriverLocation(String driverId) async {
    try {
      print('📍 [TRACKING] Récupération position livreur: $driverId');
      
      // Essayer d'abord avec is_online = true
      var response = await Supabase.instance.client
          .from('driver_locations')
          .select()
          .eq('driver_id', driverId)
          .eq('is_online', true)
          .order('last_updated', ascending: false)
          .limit(1)
          .maybeSingle();
      
      // Si pas trouvé, essayer sans la condition is_online
      if (response == null) {
        print('⚠️ [TRACKING] Aucune position en ligne trouvée, essai sans condition is_online');
        response = await Supabase.instance.client
            .from('driver_locations')
            .select()
            .eq('driver_id', driverId)
            .order('last_updated', ascending: false)
            .limit(1)
            .maybeSingle();
      }
      
      if (response != null) {
        print('✅ [TRACKING] Position récupérée: ${response['latitude']}, ${response['longitude']}');
        print('✅ [TRACKING] is_online: ${response['is_online']}');
      } else {
        print('⚠️ [TRACKING] Aucune position trouvée pour le livreur');
      }
      
      return response;
    } catch (e) {
      print('❌ [TRACKING] Erreur récupération position: $e');
      return null;
    }
  }

  /// Obtenir tous les livreurs en ligne
  static Future<List<Map<String, dynamic>>> getOnlineDrivers() async {
    try {
      print('📍 [TRACKING] Récupération livreurs en ligne...');
      
      final response = await Supabase.instance.client
          .from('online_drivers')
          .select()
          .order('last_updated', ascending: false);
      
      print('✅ [TRACKING] ${response.length} livreurs en ligne trouvés');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [TRACKING] Erreur récupération livreurs en ligne: $e');
      return [];
    }
  }

  /// Assigner une commande à un livreur
  static Future<bool> assignOrderToDriver({
    required String orderId,
    required String driverId,
    DateTime? estimatedDeliveryTime,
    String notes = '',
  }) async {
    try {
      print('📍 [TRACKING] Assignation commande $orderId au livreur $driverId');
      
      final response = await Supabase.instance.client
          .from('delivery_assignments')
          .insert({
        'order_id': orderId,
        'driver_id': driverId,
        'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
        'status': 'assigned',
        'notes': notes,
      });

      print('✅ [TRACKING] Commande assignée avec succès');
      return true;
    } catch (e) {
      print('❌ [TRACKING] Erreur assignation commande: $e');
      return false;
    }
  }

  /// Mettre à jour le statut d'une assignation
  static Future<bool> updateAssignmentStatus({
    required String assignmentId,
    required String status,
    String? notes,
    DateTime? actualDeliveryTime,
  }) async {
    try {
      print('📍 [TRACKING] Mise à jour statut assignation: $assignmentId -> $status');
      
      final updateData = {
        'status': status,
        'last_updated': DateTime.now().toIso8601String(),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      if (actualDeliveryTime != null) {
        updateData['actual_delivery_time'] = actualDeliveryTime.toIso8601String();
      }

      await Supabase.instance.client
          .from('delivery_assignments')
          .update(updateData)
          .eq('id', assignmentId);

      print('✅ [TRACKING] Statut mis à jour avec succès');
      return true;
    } catch (e) {
      print('❌ [TRACKING] Erreur mise à jour statut: $e');
      return false;
    }
  }

  /// Obtenir les livraisons actives d'un livreur
  static Future<List<Map<String, dynamic>>> getDriverActiveDeliveries(String driverId) async {
    try {
      print('📍 [TRACKING] Récupération livraisons actives livreur: $driverId');
      
      final response = await Supabase.instance.client
          .from('active_deliveries')
          .select()
          .eq('driver_id', driverId)
          .order('assigned_at', ascending: false);
      
      print('✅ [TRACKING] ${response.length} livraisons actives trouvées');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [TRACKING] Erreur récupération livraisons actives: $e');
      return [];
    }
  }

  /// Obtenir les détails d'une livraison active
  static Future<Map<String, dynamic>?> getActiveDeliveryDetails(String orderId) async {
    try {
      print('📍 [TRACKING] Récupération détails livraison: $orderId');
      
      final response = await Supabase.instance.client
          .from('active_deliveries')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();
      
      if (response != null) {
        print('✅ [TRACKING] Détails livraison récupérés');
      } else {
        print('⚠️ [TRACKING] Aucune livraison active trouvée');
      }
      
      return response;
    } catch (e) {
      print('❌ [TRACKING] Erreur récupération détails livraison: $e');
      return null;
    }
  }

  /// Marquer un livreur comme hors ligne
  static Future<bool> setDriverOffline(String driverId) async {
    try {
      print('📍 [TRACKING] Marquer livreur hors ligne: $driverId');
      
      await Supabase.instance.client
          .from('driver_locations')
          .update({
        'is_online': false,
        'last_updated': DateTime.now().toIso8601String(),
      })
          .eq('driver_id', driverId);

      print('✅ [TRACKING] Livreur marqué hors ligne');
      return true;
    } catch (e) {
      print('❌ [TRACKING] Erreur marquage hors ligne: $e');
      return false;
    }
  }

  /// Marquer un livreur comme en ligne
  static Future<bool> setDriverOnline(String driverId) async {
    try {
      print('📍 [TRACKING] Marquer livreur en ligne: $driverId');
      
      await Supabase.instance.client
          .from('driver_locations')
          .update({
        'is_online': true,
        'last_updated': DateTime.now().toIso8601String(),
      })
          .eq('driver_id', driverId);

      print('✅ [TRACKING] Livreur marqué en ligne');
      return true;
    } catch (e) {
      print('❌ [TRACKING] Erreur marquage en ligne: $e');
      return false;
    }
  }

  /// Calculer la distance entre un livreur et une adresse
  static Future<double?> calculateDistanceToDelivery({
    required String driverId,
    required double deliveryLatitude,
    required double deliveryLongitude,
  }) async {
    try {
      final driverLocation = await getDriverLocation(driverId);
      if (driverLocation == null) {
        return null;
      }

      final distance = LocationService.calculateDistance(
        Position(
          latitude: driverLocation['latitude'],
          longitude: driverLocation['longitude'],
          timestamp: DateTime.now(),
          accuracy: driverLocation['accuracy'] ?? 0,
          altitude: 0,
          heading: (driverLocation['heading'] ?? 0).toInt(),
          speed: driverLocation['speed'] ?? 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
        Position(
          latitude: deliveryLatitude,
          longitude: deliveryLongitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      );

      return distance;
    } catch (e) {
      print('❌ [TRACKING] Erreur calcul distance: $e');
      return null;
    }
  }

  /// Obtenir le temps de livraison estimé
  static Future<int?> getEstimatedDeliveryTime({
    required String driverId,
    required double deliveryLatitude,
    required double deliveryLongitude,
  }) async {
    try {
      final distance = await calculateDistanceToDelivery(
        driverId: driverId,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
      );

      if (distance == null) {
        return null;
      }

      return LocationService.calculateEstimatedTime(distance);
    } catch (e) {
      print('❌ [TRACKING] Erreur calcul temps estimé: $e');
      return null;
    }
  }

  /// Formater les informations de position pour l'affichage
  static Map<String, String> formatLocationInfo(Map<String, dynamic> location) {
    return {
      'position': '${location['latitude'].toStringAsFixed(6)}, ${location['longitude'].toStringAsFixed(6)}',
      'accuracy': LocationService.formatAccuracy(location['accuracy'] ?? 0),
      'speed': LocationService.formatSpeed(location['speed'] ?? -1),
      'heading': LocationService.formatHeading(location['heading'] ?? -1),
      'battery': '${location['battery_level'] ?? 'N/A'}%',
      'lastSeen': _formatLastSeen(location['last_updated']),
    };
  }

  static String _formatLastSeen(String? lastUpdated) {
    if (lastUpdated == null) {
      return 'N/A';
    }

    final lastSeen = DateTime.parse(lastUpdated);
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return 'Il y a ${difference.inDays} j';
    }
  }
}
