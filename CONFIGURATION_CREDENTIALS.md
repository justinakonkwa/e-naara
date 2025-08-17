# 🔑 Configuration des Identifiants Supabase

Ce guide vous explique comment configurer les identifiants Supabase dans votre application ShopFlow.

## 📋 **Étapes de configuration :**

### **1. Récupérer vos clés Supabase**

#### **A. Aller sur Supabase :**
1. Ouvrez [supabase.com](https://supabase.com)
2. Connectez-vous à votre compte
3. Sélectionnez votre projet ShopFlow

#### **B. Accéder aux paramètres API :**
1. Dans le menu de gauche, cliquez sur **"Settings"**
2. Cliquez sur **"API"**

#### **C. Copier vos identifiants :**
Vous verrez deux sections importantes :

**🔗 Project URL :**
```
https://votre-projet.supabase.co
```

**🔑 anon public :**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvdHJlLXByb2pldCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjM5NzQ5NjAwLCJleHAiOjE5NTUzMjU2MDB9.votre-cle-ici
```

### **2. Modifier le fichier de configuration**

#### **A. Ouvrir le fichier :**
```
lib/config/supabase_config.dart
```

#### **B. Remplacer les valeurs :**

```dart
class SupabaseConfig {
  // Remplacez ces valeurs par vos propres clés Supabase
  static const String supabaseUrl = 'https://votre-projet.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  // ...
}
```

**⚠️ IMPORTANT :**
- Remplacez `https://votre-projet.supabase.co` par votre vraie URL
- Remplacez `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` par votre vraie clé anonyme
- Gardez les guillemets `'` autour des valeurs

### **3. Exemple de configuration complète :**

```dart
class SupabaseConfig {
  // =====================================================
  // 🔑 IDENTIFIANTS SUPABASE - À MODIFIER ICI
  // =====================================================
  
  // Votre URL de projet Supabase
  static const String supabaseUrl = 'https://abcdefghijklmnop.supabase.co';
  
  // Votre clé anonyme publique
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYzOTc0OTYwMCwiZXhwIjoxOTU1MzI1NjAwfQ.votre-cle-ici';
  
  // =====================================================
  // 📋 TABLES DE LA BASE DE DONNÉES
  // =====================================================
  static const String productsTable = 'products';
  static const String categoriesTable = 'categories';
  static const String usersTable = 'users';
  static const String cartItemsTable = 'cart_items';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';
  static const String reviewsTable = 'reviews';
  static const String wishlistTable = 'wishlist';
  static const String promoCodesTable = 'promo_codes';
  
  // =====================================================
  // 🗂️ BUCKETS DE STOCKAGE
  // =====================================================
  static const String productImagesBucket = 'product-images';
  static const String userAvatarsBucket = 'user-avatars';
}
```

## 🔒 **Sécurité des identifiants :**

### **✅ Bonnes pratiques :**
- ✅ La clé `anon public` est **publique** et peut être dans le code
- ✅ Elle est conçue pour être utilisée côté client
- ✅ Les politiques RLS protègent vos données

### **❌ À ne PAS faire :**
- ❌ Ne partagez jamais la clé `service_role` (privée)
- ❌ Ne committez pas de vraies clés dans Git (utilisez des variables d'environnement en production)
- ❌ Ne mettez pas les clés dans des endroits publics

## 🧪 **Tester la configuration :**

### **1. Installer les dépendances :**
```bash
flutter pub get
```

### **2. Lancer l'application :**
```bash
flutter run
```

### **3. Vérifier la connexion :**
- L'application devrait se lancer sans erreur
- Vous devriez voir l'écran d'authentification
- Créez un compte pour tester

## 🚨 **Dépannage :**

### **Erreur de connexion :**
- ✅ Vérifiez que l'URL est correcte
- ✅ Vérifiez que la clé anonyme est complète
- ✅ Vérifiez que votre projet Supabase est actif

### **Erreur d'authentification :**
- ✅ Vérifiez que Supabase Auth est activé
- ✅ Vérifiez que les tables sont créées
- ✅ Vérifiez les politiques RLS

### **Erreur de base de données :**
- ✅ Vérifiez que les scripts SQL ont été exécutés
- ✅ Vérifiez que les tables existent
- ✅ Vérifiez les permissions utilisateur

## 📱 **Variables d'environnement (optionnel) :**

Pour une configuration plus sécurisée en production :

### **1. Créer un fichier `.env` :**
```
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### **2. Utiliser flutter_dotenv :**
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
```

## ✅ **Vérification finale :**

Après avoir configuré vos identifiants :

1. ✅ L'application se lance sans erreur
2. ✅ L'écran d'authentification s'affiche
3. ✅ Vous pouvez créer un compte
4. ✅ Vous pouvez vous connecter
5. ✅ Les produits s'affichent
6. ✅ Le panier fonctionne

**🎉 Félicitations ! Votre application ShopFlow est maintenant connectée à Supabase !**
