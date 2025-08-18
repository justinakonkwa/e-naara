import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:ecommerce/services/location_service.dart';
import 'package:ecommerce/services/tracking_service.dart';

class DriverTrackingService {
  static StreamSubscription<Position>? _locationSubscription;
  static Timer? _updateTimer;
  static Timer? _batteryTimer;
  static String? _currentDriverId;
  static bool _isTracking = false;
  static bool _isOnline = true;

  /// Démarrer le tracking pour un livreur
  static Future<bool> startTracking(String driverId) async {
    try {
      print('🚚 [DRIVER_TRACKING] Démarrage tracking pour livreur: $driverId');
      
      _currentDriverId = driverId;
      
      // Vérifier les permissions
      final hasPermission = await LocationService.requestLocationPermission();
      if (!hasPermission) {
        print('❌ [DRIVER_TRACKING] Permission de localisation refusée');
        return false;
      }

      // Marquer le livreur comme en ligne
      await TrackingService.setDriverOnline(driverId);
      _isOnline = true;

      // Démarrer le stream de localisation
      _locationSubscription = LocationService.getLocationStream().listen(
        (position) {
          _updateDriverLocation(position);
        },
        onError: (error) {
          print('❌ [DRIVER_TRACKING] Erreur stream: $error');
        },
      );

      // Mettre à jour toutes les 30 secondes (backup)
      _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _forceLocationUpdate();
      });

      // Vérifier la batterie toutes les 5 minutes
      _batteryTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _checkBatteryLevel();
      });

      _isTracking = true;
      print('✅ [DRIVER_TRACKING] Tracking démarré avec succès');
      return true;
    } catch (e) {
      print('❌ [DRIVER_TRACKING] Erreur démarrage tracking: $e');
      return false;
    }
  }

  /// Arrêter le tracking
  static Future<void> stopTracking() async {
    try {
      print('🚚 [DRIVER_TRACKING] Arrêt du tracking...');
      
      _isTracking = false;
      
      // Annuler les subscriptions
      await _locationSubscription?.cancel();
      _updateTimer?.cancel();
      _batteryTimer?.cancel();
      
      // Marquer le livreur comme hors ligne
      if (_currentDriverId != null) {
        await TrackingService.setDriverOffline(_currentDriverId!);
        _isOnline = false;
      }
      
      _currentDriverId = null;
      print('✅ [DRIVER_TRACKING] Tracking arrêté');
    } catch (e) {
      print('❌ [DRIVER_TRACKING] Erreur arrêt tracking: $e');
    }
  }

  /// Mettre à jour la position du livreur
  static Future<void> _updateDriverLocation(Position position) async {
    if (!_isTracking || _currentDriverId == null) {
      return;
    }

    try {
      // Vérifier si la position est valide
      if (!LocationService.isValidPosition(position)) {
        print('⚠️ [DRIVER_TRACKING] Position invalide, ignorée');
        return;
      }

      // Obtenir le niveau de batterie
      final batteryLevel = await _getBatteryLevel();

      // Mettre à jour la position
      final success = await TrackingService.updateDriverLocationFromPosition(
        driverId: _currentDriverId!,
        position: position,
        batteryLevel: batteryLevel,
        isOnline: _isOnline,
      );

      if (success) {
        print('📍 [DRIVER_TRACKING] Position mise à jour: ${position.latitude}, ${position.longitude}');
      } else {
        print('❌ [DRIVER_TRACKING] Échec mise à jour position');
      }
    } catch (e) {
      print('❌ [DRIVER_TRACKING] Erreur mise à jour position: $e');
    }
  }

  /// Forcer une mise à jour de position
  static Future<void> _forceLocationUpdate() async {
    if (!_isTracking || _currentDriverId == null) {
      return;
    }

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        await _updateDriverLocation(position);
      }
    } catch (e) {
      print('❌ [DRIVER_TRACKING] Erreur mise à jour forcée: $e');
    }
  }

  /// Vérifier le niveau de batterie
  static Future<void> _checkBatteryLevel() async {
    if (!_isTracking || _currentDriverId == null) {
      return;
    }

    try {
      final batteryLevel = await _getBatteryLevel();
      
      // Si la batterie est faible, réduire la fréquence de mise à jour
      if (batteryLevel != null && batteryLevel < 20) {
        print('⚠️ [DRIVER_TRACKING] Batterie faible ($batteryLevel%), optimisation activée');
        _optimizeForLowBattery();
      }
    } catch (e) {
      print('❌ [DRIVER_TRACKING] Erreur vérification batterie: $e');
    }
  }

  /// Obtenir le niveau de batterie
  static Future<int?> _getBatteryLevel() async {
    try {
      if (Platform.isAndroid) {
        // Pour Android, on peut utiliser des plugins spécifiques
        // Pour l'instant, on retourne null
        return null;
      } else if (Platform.isIOS) {
        // Pour iOS, on peut utiliser des plugins spécifiques
        // Pour l'instant, on retourne null
        return null;
      }
      return null;
    } catch (e) {
      print('❌ [DRIVER_TRACKING] Erreur récupération niveau batterie: $e');
      return null;
    }
  }

  /// Optimiser pour une batterie faible
  static void _optimizeForLowBattery() {
    // Réduire la fréquence de mise à jour
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _forceLocationUpdate();
    });
  }

  /// Mettre en pause le tracking
  static Future<void> pauseTracking() async {
    try {
      print('⏸️ [DRIVER_TRACKING] Mise en pause du tracking...');
      
      _isTracking = false;
      
      // Marquer comme hors ligne temporairement
      if (_currentDriverId != null) {
        await TrackingService.setDriverOffline(_currentDriverId!);
        _isOnline = false;
      }
      
      print('✅ [DRIVER_TRACKING] Tracking mis en pause');
    } catch (e) {
      print('❌ [DRIVER_TRACKING] Erreur mise en pause: $e');
    }
  }

  /// Reprendre le tracking
  static Future<void> resumeTracking() async {
    try {
      print('▶️ [DRIVER_TRACKING] Reprise du tracking...');
      
      _isTracking = true;
      
      // Marquer comme en ligne
      if (_currentDriverId != null) {
        await TrackingService.setDriverOnline(_currentDriverId!);
        _isOnline = true;
      }
      
      print('✅ [DRIVER_TRACKING] Tracking repris');
    } catch (e) {
      print('❌ [DRIVER_TRACKING] Erreur reprise: $e');
    }
  }

  /// Changer les paramètres de précision
  static void setAccuracy(LocationAccuracy accuracy) {
    print('🎯 [DRIVER_TRACKING] Changement précision: $accuracy');
    
    // Arrêter le stream actuel
    _locationSubscription?.cancel();
    
    // Redémarrer avec la nouvelle précision
    if (_currentDriverId != null) {
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: accuracy == LocationAccuracy.best ? 5 : 10,
          timeLimit: const Duration(seconds: 30),
        ),
      ).listen(
        (position) {
          _updateDriverLocation(position);
        },
        onError: (error) {
          print('❌ [DRIVER_TRACKING] Erreur stream: $error');
        },
      );
    }
  }

  /// Obtenir le statut du tracking
  static Map<String, dynamic> getTrackingStatus() {
    return {
      'isTracking': _isTracking,
      'isOnline': _isOnline,
      'driverId': _currentDriverId,
      'hasLocationSubscription': _locationSubscription != null,
      'hasUpdateTimer': _updateTimer != null,
      'hasBatteryTimer': _batteryTimer != null,
    };
  }

  /// Vérifier si le tracking est actif
  static bool get isTracking => _isTracking;

  /// Vérifier si le livreur est en ligne
  static bool get isOnline => _isOnline;

  /// Obtenir l'ID du livreur actuel
  static String? get currentDriverId => _currentDriverId;

  /// Nettoyer les ressources
  static void dispose() {
    _locationSubscription?.cancel();
    _updateTimer?.cancel();
    _batteryTimer?.cancel();
    _currentDriverId = null;
    _isTracking = false;
    _isOnline = false;
  }
}


