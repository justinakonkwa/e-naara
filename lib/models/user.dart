import 'package:ecommerce/models/order.dart';
import 'package:ecommerce/models/user_role.dart';

class AppUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final UserRole role;
  final List<UserShippingAddress> addresses;
  final List<UserPaymentMethod> paymentMethods;
  final List<String> wishlist;
  final UserPreferences preferences;

  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    this.role = UserRole.user,
    required this.addresses,
    required this.paymentMethods,
    required this.wishlist,
    required this.preferences,
  });

  String get fullName => '$firstName $lastName';
  String get displayName => firstName;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    // Déterminer le rôle de l'utilisateur
    UserRole role = UserRole.user;
    if (json['role'] != null) {
      switch (json['role']) {
        case 'driver':
          role = UserRole.driver;
          break;
        case 'admin':
          role = UserRole.admin;
          break;
        default:
          role = UserRole.user;
      }
    }

    return AppUser(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      profileImageUrl: json['profile_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      role: role,
      addresses: [], // Ces données seront chargées séparément si nécessaire
      paymentMethods: [], // Ces données seront chargées séparément si nécessaire
      wishlist: [], // Cette liste sera chargée depuis la table wishlist
      preferences: const UserPreferences(
        enablePushNotifications: true,
        enableEmailNotifications: true,
        enableSmsNotifications: false,
        language: 'fr',
        currency: 'EUR',
        darkMode: false,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'role': role.databaseValue,
    };
  }
}

class UserShippingAddress {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;

  const UserShippingAddress({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.isDefault,
  });

  factory UserShippingAddress.fromJson(Map<String, dynamic> json) {
    return UserShippingAddress(
      id: json['id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      addressLine1: json['address_line1'],
      addressLine2: json['address_line2'],
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

class UserPaymentMethod {
  final String id;
  final String type;
  final String displayName;
  final String lastFour;
  final String? expiryDate;
  final bool isDefault;

  const UserPaymentMethod({
    required this.id,
    required this.type,
    required this.displayName,
    required this.lastFour,
    this.expiryDate,
    required this.isDefault,
  });

  factory UserPaymentMethod.fromJson(Map<String, dynamic> json) {
    return UserPaymentMethod(
      id: json['id'],
      type: json['type'],
      displayName: json['display_name'],
      lastFour: json['last_four'],
      expiryDate: json['expiry_date'],
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

class UserPreferences {
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableSmsNotifications;
  final String language;
  final String currency;
  final bool darkMode;

  const UserPreferences({
    required this.enablePushNotifications,
    required this.enableEmailNotifications,
    required this.enableSmsNotifications,
    required this.language,
    required this.currency,
    required this.darkMode,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      enablePushNotifications: json['enable_push_notifications'] ?? true,
      enableEmailNotifications: json['enable_email_notifications'] ?? true,
      enableSmsNotifications: json['enable_sms_notifications'] ?? false,
      language: json['language'] ?? 'fr',
      currency: json['currency'] ?? 'EUR',
      darkMode: json['dark_mode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable_push_notifications': enablePushNotifications,
      'enable_email_notifications': enableEmailNotifications,
      'enable_sms_notifications': enableSmsNotifications,
      'language': language,
      'currency': currency,
      'dark_mode': darkMode,
    };
  }
}

class UserStats {
  final int totalOrders;
  final double totalSpent;
  final int reviewsWritten;
  final int wishlistItems;
  final DateTime lastOrderDate;

  const UserStats({
    required this.totalOrders,
    required this.totalSpent,
    required this.reviewsWritten,
    required this.wishlistItems,
    required this.lastOrderDate,
  });
}