import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ecommerce/models/order.dart';

class DeliveryNotificationService extends ChangeNotifier {
  static final DeliveryNotificationService _instance = DeliveryNotificationService._internal();
  factory DeliveryNotificationService() => _instance;
  DeliveryNotificationService._internal();

  // Liste des commandes en attente de livraison
  List<DeliveryRequest> _pendingDeliveries = [];
  
  // Livreur connecté
  DeliveryDriver? _currentDriver;
  
  // Stream pour les notifications en temps réel
  final StreamController<DeliveryRequest> _notificationController = StreamController<DeliveryRequest>.broadcast();

  // Getters
  List<DeliveryRequest> get pendingDeliveries => _pendingDeliveries;
  DeliveryDriver? get currentDriver => _currentDriver;
  Stream<DeliveryRequest> get notificationStream => _notificationController.stream;

  /// Simule l'envoi d'une notification de nouvelle commande
  void sendDeliveryNotification(SimpleOrder order) {
    final deliveryRequest = DeliveryRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      order: order,
      status: DeliveryStatus.pending,
      createdAt: DateTime.now(),
      estimatedPickupTime: DateTime.now().add(const Duration(minutes: 10)),
      estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 45)),
    );

    _pendingDeliveries.add(deliveryRequest);
    _notificationController.add(deliveryRequest);
    
    print('🚚 [DELIVERY] Notification envoyée pour la commande #${order.id.substring(0, 8)}');
    notifyListeners();
  }

  /// Accepte une commande de livraison
  Future<bool> acceptDelivery(String deliveryId) async {
    final index = _pendingDeliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) return false;

    // Simuler un délai de traitement
    await Future.delayed(const Duration(seconds: 1));

    _pendingDeliveries[index] = _pendingDeliveries[index].copyWith(
      status: DeliveryStatus.accepted,
      acceptedAt: DateTime.now(),
      driverId: _currentDriver?.id,
    );

    print('✅ [DELIVERY] Commande acceptée: $deliveryId');
    notifyListeners();
    return true;
  }

  /// Refuse une commande de livraison
  Future<bool> declineDelivery(String deliveryId, String reason) async {
    final index = _pendingDeliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) return false;

    await Future.delayed(const Duration(seconds: 1));

    _pendingDeliveries[index] = _pendingDeliveries[index].copyWith(
      status: DeliveryStatus.declined,
      declinedAt: DateTime.now(),
      declineReason: reason,
    );

    print('❌ [DELIVERY] Commande refusée: $deliveryId - $reason');
    notifyListeners();
    return true;
  }

  /// Marque une livraison comme en cours
  Future<bool> startDelivery(String deliveryId) async {
    final index = _pendingDeliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) return false;

    await Future.delayed(const Duration(seconds: 1));

    _pendingDeliveries[index] = _pendingDeliveries[index].copyWith(
      status: DeliveryStatus.inProgress,
      startedAt: DateTime.now(),
    );

    print('🚗 [DELIVERY] Livraison démarrée: $deliveryId');
    notifyListeners();
    return true;
  }

  /// Marque une livraison comme terminée
  Future<bool> completeDelivery(String deliveryId) async {
    final index = _pendingDeliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) return false;

    await Future.delayed(const Duration(seconds: 1));

    _pendingDeliveries[index] = _pendingDeliveries[index].copyWith(
      status: DeliveryStatus.completed,
      completedAt: DateTime.now(),
    );

    print('🎉 [DELIVERY] Livraison terminée: $deliveryId');
    notifyListeners();
    return true;
  }

  /// Connecte un livreur
  void connectDriver(DeliveryDriver driver) {
    _currentDriver = driver;
    print('👤 [DELIVERY] Livreur connecté: ${driver.name}');
    notifyListeners();
  }

  /// Déconnecte le livreur
  void disconnectDriver() {
    _currentDriver = null;
    print('👤 [DELIVERY] Livreur déconnecté');
    notifyListeners();
  }

  /// Nettoie les anciennes commandes
  void cleanupOldDeliveries() {
    final now = DateTime.now();
    _pendingDeliveries.removeWhere((delivery) {
      return delivery.createdAt.isBefore(now.subtract(const Duration(hours: 24)));
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationController.close();
    super.dispose();
  }
}

/// Statut de livraison
enum DeliveryStatus {
  pending,
  accepted,
  declined,
  inProgress,
  completed,
  cancelled,
}

/// Demande de livraison
class DeliveryRequest {
  final String id;
  final SimpleOrder order;
  final DeliveryStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? driverId;
  final String? declineReason;
  final DateTime estimatedPickupTime;
  final DateTime estimatedDeliveryTime;

  const DeliveryRequest({
    required this.id,
    required this.order,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.declinedAt,
    this.startedAt,
    this.completedAt,
    this.driverId,
    this.declineReason,
    required this.estimatedPickupTime,
    required this.estimatedDeliveryTime,
  });

  DeliveryRequest copyWith({
    String? id,
    SimpleOrder? order,
    DeliveryStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? driverId,
    String? declineReason,
    DateTime? estimatedPickupTime,
    DateTime? estimatedDeliveryTime,
  }) {
    return DeliveryRequest(
      id: id ?? this.id,
      order: order ?? this.order,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      declinedAt: declinedAt ?? this.declinedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      driverId: driverId ?? this.driverId,
      declineReason: declineReason ?? this.declineReason,
      estimatedPickupTime: estimatedPickupTime ?? this.estimatedPickupTime,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.accepted:
        return 'Acceptée';
      case DeliveryStatus.declined:
        return 'Refusée';
      case DeliveryStatus.inProgress:
        return 'En cours';
      case DeliveryStatus.completed:
        return 'Terminée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }

  bool get canBeAccepted => status == DeliveryStatus.pending;
  bool get canBeStarted => status == DeliveryStatus.accepted;
  bool get canBeCompleted => status == DeliveryStatus.inProgress;
}

/// Livreur
class DeliveryDriver {
  final String id;
  final String name;
  final String phoneNumber;
  final String vehicleType;
  final String vehiclePlate;
  final bool isAvailable;
  final double currentLatitude;
  final double currentLongitude;

  const DeliveryDriver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.vehicleType,
    required this.vehiclePlate,
    this.isAvailable = true,
    this.currentLatitude = 0.0,
    this.currentLongitude = 0.0,
  });

  String get displayName => '$name ($vehiclePlate)';
}
