import 'dart:convert';
import 'dart:ui';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ecommerce/models/order.dart';

class QRCodeService {
  /// Génère un QR code pour une commande
  static QrPainter generateOrderQRCode(SimpleOrder order) {
    final qrData = {
      'order_id': order.id,
      'user_id': order.userId,
      'total_amount': order.totalAmount,
      'shipping_address': order.shippingAddress,
      'created_at': order.createdAt.toIso8601String(),
      'type': 'delivery_confirmation',
    };

    final jsonString = jsonEncode(qrData);
    
    return QrPainter(
      data: jsonString,
      version: QrVersions.auto,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );
  }

  /// Décode les données du QR code
  static Map<String, dynamic>? decodeQRCode(String qrData) {
    try {
      final decoded = jsonDecode(qrData);
      return decoded as Map<String, dynamic>;
    } catch (e) {
      print('Erreur lors du décodage du QR code: $e');
      return null;
    }
  }

  /// Valide si le QR code est valide pour une commande
  static bool isValidOrderQRCode(String qrData) {
    final decoded = decodeQRCode(qrData);
    if (decoded == null) return false;

    return decoded.containsKey('order_id') && 
           decoded.containsKey('type') && 
           decoded['type'] == 'delivery_confirmation';
  }

  /// Extrait l'ID de commande du QR code
  static String? extractOrderId(String qrData) {
    final decoded = decodeQRCode(qrData);
    return decoded?['order_id'] as String?;
  }

  /// Génère un code de commande court pour saisie manuelle
  static String generateShortCode(String orderId) {
    // Prend les 8 premiers caractères de l'ID
    return orderId.substring(0, 8).toUpperCase();
  }

  /// Valide un code de commande court
  static bool isValidShortCode(String shortCode, String fullOrderId) {
    return shortCode.toUpperCase() == generateShortCode(fullOrderId);
  }

  /// Valide si un code peut être un code court valide
  static bool isValidShortCodeFormat(String code) {
    // Un code court doit faire exactement 8 caractères et contenir seulement des caractères hexadécimaux
    if (code.length != 8) return false;
    
    // Vérifier que tous les caractères sont hexadécimaux (0-9, A-F, a-f)
    final hexPattern = RegExp(r'^[0-9A-Fa-f]{8}$');
    return hexPattern.hasMatch(code);
  }

  /// Normalise un code court (met en majuscules)
  static String normalizeShortCode(String code) {
    return code.toUpperCase();
  }
}
