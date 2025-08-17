import 'package:ecommerce/models/cart.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  returned,
}

class ShippingAddress {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;

  const ShippingAddress({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      addressLine1: json['address_line1'],
      addressLine2: json['address_line2'] ?? '',
      city: json['city'],
      state: json['state'],
      postalCode: json['postal_code'],
      country: json['country'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
    };
  }
}

class PaymentMethod {
  final String id;
  final String type; // 'card', 'paypal', 'apple_pay', 'google_pay'
  final String displayName;
  final String lastFour;
  final String expiryDate;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.displayName,
    required this.lastFour,
    this.expiryDate = '',
    this.isDefault = false,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      type: json['type'],
      displayName: json['display_name'],
      lastFour: json['last_four'],
      expiryDate: json['expiry_date'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'display_name': displayName,
      'last_four': lastFour,
      'expiry_date': expiryDate,
      'is_default': isDefault,
    };
  }
}

class OrderTrackingEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;

  const OrderTrackingEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isCompleted,
  });

  factory OrderTrackingEvent.fromJson(Map<String, dynamic> json) {
    return OrderTrackingEvent(
      title: json['title'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'is_completed': isCompleted,
    };
  }
}

// Modèle Order simplifié pour la compatibilité avec Supabase
class SimpleOrder {
  final String id;
  final String userId;
  final double totalAmount;
  final String shippingAddress;
  final String paymentMethod;
  final String status;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? driverId;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  const SimpleOrder({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.status,
    this.trackingNumber,
    required this.createdAt,
    required this.updatedAt,
    this.driverId,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'processing':
        return 'En traitement';
      case 'shipped':
        return 'Expédié';
      case 'out_for_delivery':
        return 'En livraison';
      case 'delivered':
        return 'Livré';
      case 'cancelled':
        return 'Annulé';
      case 'returned':
        return 'Retourné';
      default:
        return 'Inconnu';
    }
  }

  factory SimpleOrder.fromJson(Map<String, dynamic> json) {
    return SimpleOrder(
      id: json['id'],
      userId: json['user_id'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      shippingAddress: json['shipping_address'],
      paymentMethod: json['payment_method'],
      status: json['status'],
      trackingNumber: json['tracking_number'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      driverId: json['driver_id'],
      assignedAt: json['assigned_at'] != null ? DateTime.parse(json['assigned_at']) : null,
      pickedUpAt: json['picked_up_at'] != null ? DateTime.parse(json['picked_up_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_amount': totalAmount,
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
      'status': status,
      'tracking_number': trackingNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'driver_id': driverId,
      'assigned_at': assignedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }
}

class Order {
  final String id;
  final List<CartItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final ShippingAddress shippingAddress;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double shippingCost;
  final double tax;
  final double discount;
  final double total;
  final String? promoCode;
  final List<OrderTrackingEvent> trackingEvents;
  final String? trackingNumber;

  const Order({
    required this.id,
    required this.items,
    required this.status,
    required this.createdAt,
    this.estimatedDelivery,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.subtotal,
    required this.shippingCost,
    required this.tax,
    required this.discount,
    required this.total,
    this.promoCode,
    required this.trackingEvents,
    this.trackingNumber,
  });

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmé';
      case OrderStatus.processing:
        return 'En traitement';
      case OrderStatus.shipped:
        return 'Expédié';
      case OrderStatus.outForDelivery:
        return 'En livraison';
      case OrderStatus.delivered:
        return 'Livré';
      case OrderStatus.cancelled:
        return 'Annulé';
      case OrderStatus.returned:
        return 'Retourné';
    }
  }

  bool get canBeCancelled => 
      status == OrderStatus.pending || status == OrderStatus.confirmed;
  
  bool get isDelivered => status == OrderStatus.delivered;
  
  bool get isActive => 
      status != OrderStatus.delivered && 
      status != OrderStatus.cancelled && 
      status != OrderStatus.returned;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson(item))
          .toList() ?? [],
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.parse(json['estimated_delivery'])
          : null,
      shippingAddress: ShippingAddress.fromJson(json['shipping_address']),
      paymentMethod: PaymentMethod.fromJson(json['payment_method']),
      subtotal: (json['subtotal'] as num).toDouble(),
      shippingCost: (json['shipping_cost'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      promoCode: json['promo_code'],
      trackingEvents: (json['tracking_events'] as List<dynamic>?)
          ?.map((event) => OrderTrackingEvent.fromJson(event))
          .toList() ?? [],
      trackingNumber: json['tracking_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
      'shipping_address': shippingAddress.toJson(),
      'payment_method': paymentMethod.toJson(),
      'subtotal': subtotal,
      'shipping_cost': shippingCost,
      'tax': tax,
      'discount': discount,
      'total': total,
      'promo_code': promoCode,
      'tracking_events': trackingEvents.map((event) => event.toJson()).toList(),
      'tracking_number': trackingNumber,
    };
  }
}