import 'package:geolocator/geolocator.dart';

class LocationService {
  static const _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Mettre à jour tous les 10m
    timeLimit: Duration(seconds: 30),
  );

  /// Vérifier et demander les permissions de localisation
  static Future<bool> requestLocationPermission() async {
    try {
      print('📍 [LOCATION] Vérification des permissions...');
      
      // Vérifier le service de localisation
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ [LOCATION] Service de localisation désactivé');
        return false;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        print('📍 [LOCATION] Permission refusée, demande en cours...');
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          print('❌ [LOCATION] Permission refusée par l\'utilisateur');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ [LOCATION] Permission refusée définitivement');
        return false;
      }

      print('✅ [LOCATION] Permission accordée');
      return true;
    } catch (e) {
      print('❌ [LOCATION] Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }

  /// Obtenir la position actuelle
  static Future<Position?> getCurrentLocation() async {
    try {
      print('📍 [LOCATION] Récupération de la position actuelle...');
      
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('❌ [LOCATION] Pas de permission pour la localisation');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      print('✅ [LOCATION] Position récupérée: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ [LOCATION] Erreur lors de la récupération de la position: $e');
      return null;
    }
  }

  /// Obtenir un stream de positions en temps réel
  static Stream<Position> getLocationStream() {
    print('📍 [LOCATION] Démarrage du stream de localisation...');
    
    return Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).handleError((error) {
      print('❌ [LOCATION] Erreur dans le stream: $error');
    });
  }

  /// Calculer la distance entre deux positions
  static double calculateDistance(Position start, Position end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Calculer le temps de trajet estimé (en minutes)
  static int calculateEstimatedTime(double distanceInMeters, {double averageSpeedKmh = 30}) {
    // Convertir la vitesse en m/s
    final speedMs = averageSpeedKmh * 1000 / 3600;
    // Calculer le temps en secondes
    final timeSeconds = distanceInMeters / speedMs;
    // Convertir en minutes
    return (timeSeconds / 60).round();
  }

  /// Vérifier si la position est valide
  static bool isValidPosition(Position position) {
    return position.latitude != 0 && 
           position.longitude != 0 && 
           position.accuracy <= 100; // Précision de moins de 100m
  }

  /// Obtenir les paramètres de localisation optimisés pour la batterie
  static LocationSettings getBatteryOptimizedSettings() {
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50, // Mettre à jour tous les 50m
      timeLimit: Duration(seconds: 60),
    );
  }

  /// Obtenir les paramètres de localisation haute précision
  static LocationSettings getHighAccuracySettings() {
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5, // Mettre à jour tous les 5m
      timeLimit: Duration(seconds: 15),
    );
  }

  /// Vérifier si le GPS est activé
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('❌ [LOCATION] Erreur lors de la vérification du GPS: $e');
      return false;
    }
  }

  /// Obtenir la dernière position connue
  static Future<Position?> getLastKnownPosition() async {
    try {
      print('📍 [LOCATION] Récupération de la dernière position connue...');
      
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        print('✅ [LOCATION] Dernière position trouvée: ${position.latitude}, ${position.longitude}');
      } else {
        print('⚠️ [LOCATION] Aucune position connue');
      }
      
      return position;
    } catch (e) {
      print('❌ [LOCATION] Erreur lors de la récupération de la dernière position: $e');
      return null;
    }
  }

  /// Formater une position pour l'affichage
  static String formatPosition(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  /// Formater la précision pour l'affichage
  static String formatAccuracy(double accuracy) {
    if (accuracy < 10) {
      return 'Très précise (< 10m)';
    } else if (accuracy < 50) {
      return 'Précise (< 50m)';
    } else if (accuracy < 100) {
      return 'Moyenne (< 100m)';
    } else {
      return 'Faible (> 100m)';
    }
  }

  /// Formater la vitesse pour l'affichage
  static String formatSpeed(double speed) {
    if (speed < 0) {
      return 'N/A';
    }
    
    final speedKmh = speed * 3.6; // Convertir m/s en km/h
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }

  /// Formater la direction pour l'affichage
  static String formatHeading(int heading) {
    if (heading < 0) {
      return 'N/A';
    }
    
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    final index = ((heading + 22.5) / 45).floor() % 8;
    return '${directions[index]} (${heading}°)';
  }
}
