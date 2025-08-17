# 🎭 Système de Rôles Utilisateur

## 📋 Vue d'ensemble

Le système de rôles permet de séparer les interfaces et fonctionnalités selon le type d'utilisateur, garantissant une expérience adaptée et sécurisée.

## 🎯 Rôles Disponibles

### **👤 Client (`user`)**
- **Accès** : Fonctionnalités d'achat et de suivi
- **Interface** : Catalogue, panier, commandes personnelles
- **Permissions** : Lecture de ses propres données

### **🚚 Livreur (`driver`)**
- **Accès** : Fonctionnalités de livraison
- **Interface** : Dashboard livreur, scanner QR, gestion des commandes
- **Permissions** : Gestion des commandes assignées

### **⚙️ Administrateur (`admin`)**
- **Accès** : Fonctionnalités complètes
- **Interface** : Toutes les interfaces + administration
- **Permissions** : Accès complet à la plateforme

## 🔐 Hiérarchie des Permissions

```
admin > driver > user
```

- **Admin** : Accès à tout
- **Driver** : Accès aux fonctionnalités client + livraison
- **User** : Accès aux fonctionnalités client uniquement

## 🏗️ Architecture Technique

### **Modèles de Données**

#### **`UserRole` Enum**
```dart
enum UserRole {
  user,    // Client normal
  driver,  // Livreur
  admin,   // Administrateur
}
```

#### **`AppUser` Model**
```dart
class AppUser {
  final String id;
  final String email;
  final UserRole role;  // Nouveau champ
  // ... autres champs
}
```

#### **`UserRoleManager`**
```dart
class UserRoleManager {
  static UserRole? _currentRole;
  static String? _currentUserId;
  
  // Getters et setters
  static bool get isDriver => _currentRole == UserRole.driver;
  static bool get isAdmin => _currentRole == UserRole.admin;
  static bool get isUser => _currentRole == UserRole.user;
}
```

### **Base de Données**

#### **Table `users`**
```sql
ALTER TABLE users 
ADD COLUMN role VARCHAR(20) DEFAULT 'user' 
CHECK (role IN ('user', 'driver', 'admin'));
```

#### **Index de Performance**
```sql
CREATE INDEX idx_users_role ON users(role);
```

## 🚀 Flux d'Utilisation

### **1. Inscription/Connexion**
```
Utilisateur → Auth → Rôle par défaut (user)
```

### **2. Sélection de Rôle**
```
Nouvel utilisateur → Écran de sélection → Choix du rôle
```

### **3. Interface Adaptée**
```
Rôle déterminé → Interface spécifique → Fonctionnalités appropriées
```

## 📱 Interfaces par Rôle

### **👤 Interface Client**
- **Accueil** : Catalogue, promotions, recherche
- **Navigation** : Boutique, Panier, Commandes, Profil
- **Fonctionnalités** : Achat, suivi, historique

### **🚚 Interface Livreur**
- **Accueil** : Dashboard livreur, commandes disponibles
- **Navigation** : Dashboard, Scanner QR, Historique
- **Fonctionnalités** : Assignation, récupération, livraison

### **⚙️ Interface Admin**
- **Accueil** : Dashboard admin, statistiques
- **Navigation** : Toutes les interfaces + administration
- **Fonctionnalités** : Gestion complète

## 🔧 Implémentation

### **Vérification des Permissions**
```dart
// Dans n'importe quel widget
if (UserRoleManager.hasPermission(UserRole.driver)) {
  // Afficher les fonctionnalités livreur
}

// Ou plus simple
if (UserRoleManager.isDriver) {
  // Afficher le dashboard livreur
}
```

### **Interface Conditionnelle**
```dart
Widget build(BuildContext context) {
  final currentRole = UserRoleManager.currentRole;
  
  return Column(
    children: [
      // Interface pour tous
      _buildCommonInterface(),
      
      // Interface spécifique aux livreurs
      if (currentRole?.canAccessDriverFeatures == true)
        _buildDriverInterface(),
        
      // Interface spécifique aux admins
      if (currentRole?.canAccessAdminFeatures == true)
        _buildAdminInterface(),
    ],
  );
}
```

## 🛡️ Sécurité

### **Politiques RLS (Row Level Security)**

#### **Accès Utilisateur**
```sql
-- Voir son propre profil
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (auth.uid() = id);

-- Mettre à jour son propre profil
CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid() = user_id);
```

#### **Accès Livreur**
```sql
-- Voir les commandes assignées
CREATE POLICY "Drivers can view assigned orders" ON orders
    FOR SELECT USING (auth.uid() = driver_id);

-- Mettre à jour les commandes assignées
CREATE POLICY "Drivers can update assigned orders" ON orders
    FOR UPDATE USING (auth.uid() = driver_id);
```

#### **Accès Admin**
```sql
-- Voir tous les utilisateurs
CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );
```

## 📊 Gestion des Rôles

### **Mise à Jour de Rôle**
```dart
// Dans SupabaseService
static Future<bool> updateUserRole(String userId, UserRole role) async {
  final response = await _supabase
      .from('users')
      .update({
        'role': role.databaseValue,
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', userId)
      .select()
      .single();
  
  return true;
}
```

### **Synchronisation Locale**
```dart
// Dans AuthService
if (_currentUser != null) {
  UserRoleManager.setRole(_currentUser!.role, _currentUser!.id);
}
```

## 🎨 Interface Utilisateur

### **Écran de Sélection de Rôle**
- **Design** : Cards interactives avec icônes
- **Fonctionnalités** : Sélection visuelle, confirmation
- **Navigation** : Redirection vers l'interface appropriée

### **Profil Utilisateur**
- **Affichage** : Rôle actuel avec icône et description
- **Actions** : Possibilité de changer de rôle (admin)
- **Informations** : Détails du compte et permissions

### **Navigation Adaptative**
- **Menu** : Options selon le rôle
- **Boutons** : Visibilité conditionnelle
- **Accès** : Restrictions automatiques

## 🔍 Debug et Logs

### **Logs de Rôle**
```
🎭 [AUTH] Rôle utilisateur: Livreur
🎭 [SUPABASE] Mise à jour du rôle pour l'utilisateur: user_id
✅ [SUPABASE] Rôle mis à jour: driver
```

### **Vérifications**
- Rôle chargé au démarrage
- Synchronisation avec la base de données
- Permissions vérifiées à chaque action

## 🧪 Tests

### **Scénarios de Test**
1. **Inscription** : Rôle par défaut assigné
2. **Changement de rôle** : Mise à jour en base
3. **Interface adaptée** : Affichage selon le rôle
4. **Permissions** : Accès restreint approprié

### **Requêtes de Test**
```sql
-- Vérifier les rôles
SELECT role, COUNT(*) FROM users GROUP BY role;

-- Tester les permissions
SELECT * FROM users WHERE role = 'driver';
```

## 🔮 Améliorations Futures

### **Fonctionnalités Avancées**
- **Rôles multiples** : Un utilisateur peut avoir plusieurs rôles
- **Permissions granulaires** : Contrôle fin des accès
- **Rôles temporaires** : Assignation avec expiration
- **Audit trail** : Historique des changements de rôle

### **Intégrations**
- **SSO** : Authentification unique avec rôles
- **LDAP** : Synchronisation avec annuaire d'entreprise
- **OAuth** : Rôles via fournisseurs externes

---

**Le système de rôles garantit une expérience utilisateur adaptée et sécurisée ! 🎭**
