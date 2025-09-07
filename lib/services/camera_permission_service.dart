import 'package:permission_handler/permission_handler.dart';

class CameraPermissionService {
  /// Vérifier et demander les permissions de caméra
  static Future<bool> requestCameraPermission() async {
    try {
      print('📷 [CAMERA] Vérification des permissions...');
      
      // Vérifier le statut actuel de la permission
      PermissionStatus status = await Permission.camera.status;
      
      if (status.isGranted) {
        print('✅ [CAMERA] Permission déjà accordée');
        return true;
      }
      
      if (status.isDenied) {
        print('📍 [CAMERA] Permission refusée, demande en cours...');
        status = await Permission.camera.request();
        
        if (status.isGranted) {
          print('✅ [CAMERA] Permission accordée');
          return true;
        } else {
          print('❌ [CAMERA] Permission refusée par l\'utilisateur');
          return false;
        }
      }
      
      if (status.isPermanentlyDenied) {
        print('❌ [CAMERA] Permission refusée définitivement');
        // Ouvrir les paramètres de l'app
        await openAppSettings();
        return false;
      }
      
      return false;
    } catch (e) {
      print('❌ [CAMERA] Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }
  
  /// Vérifier si la permission est accordée
  static Future<bool> isCameraPermissionGranted() async {
    try {
      PermissionStatus status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      print('❌ [CAMERA] Erreur lors de la vérification du statut: $e');
      return false;
    }
  }
  
  /// Ouvrir les paramètres de l'application
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('❌ [CAMERA] Erreur lors de l\'ouverture des paramètres: $e');
    }
  }
}

