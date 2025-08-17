enum UserRole {
  user,    // Client normal
  driver,  // Livreur
  admin,   // Administrateur
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'Client';
      case UserRole.driver:
        return 'Livreur';
      case UserRole.admin:
        return 'Administrateur';
    }
  }

  String get databaseValue {
    switch (this) {
      case UserRole.user:
        return 'user';
      case UserRole.driver:
        return 'driver';
      case UserRole.admin:
        return 'admin';
    }
  }

  bool get canAccessDriverFeatures {
    return this == UserRole.driver || this == UserRole.admin;
  }

  bool get canAccessAdminFeatures {
    return this == UserRole.admin;
  }

  bool get canManageOrders {
    return this == UserRole.driver || this == UserRole.admin;
  }

  bool get canViewAllOrders {
    return this == UserRole.admin;
  }
}

class UserRoleManager {
  static UserRole? _currentRole;
  static String? _currentUserId;

  static UserRole? get currentRole => _currentRole;
  static String? get currentUserId => _currentUserId;

  static bool get isDriver => _currentRole == UserRole.driver;
  static bool get isAdmin => _currentRole == UserRole.admin;
  static bool get isUser => _currentRole == UserRole.user;

  static void setRole(UserRole role, String userId) {
    _currentRole = role;
    _currentUserId = userId;
  }

  static void clearRole() {
    _currentRole = null;
    _currentUserId = null;
  }

  static bool hasPermission(UserRole requiredRole) {
    if (_currentRole == null) return false;
    
    switch (requiredRole) {
      case UserRole.user:
        return true; // Tout le monde peut accéder aux fonctionnalités utilisateur
      case UserRole.driver:
        return _currentRole == UserRole.driver || _currentRole == UserRole.admin;
      case UserRole.admin:
        return _currentRole == UserRole.admin;
    }
  }
}
