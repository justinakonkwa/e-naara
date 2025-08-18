# 🚚 Système de Tracking en Temps Réel

## 📋 Vue d'ensemble

Le système de tracking en temps réel permet aux clients de suivre leurs livraisons et aux livreurs de partager leur position GPS en temps réel. Ce système comprend :

- **Tracking GPS automatique** pour les livreurs
- **Suivi en temps réel** pour les clients
- **Gestion des assignations** livreur-commande
- **Optimisation batterie** intelligente
- **Interface utilisateur** moderne et intuitive

## 🏗️ Architecture

### Base de données (Supabase)

#### Tables principales

**`driver_locations`** - Positions GPS des livreurs
```sql
CREATE TABLE driver_locations (
  id UUID PRIMARY KEY,
  driver_id UUID REFERENCES auth.users(id),
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  accuracy DECIMAL(5, 2),
  speed DECIMAL(5, 2),
  heading INTEGER,
  battery_level INTEGER,
  is_online BOOLEAN DEFAULT true,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**`delivery_assignments`** - Assignations livreur-commande
```sql
CREATE TABLE delivery_assignments (
  id UUID PRIMARY KEY,
  order_id UUID REFERENCES orders(id),
  driver_id UUID REFERENCES auth.users(id),
  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  estimated_delivery_time TIMESTAMP WITH TIME ZONE,
  actual_delivery_time TIMESTAMP WITH TIME ZONE,
  status VARCHAR(50) DEFAULT 'assigned',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Vues utiles

**`online_drivers`** - Livreurs actuellement en ligne
**`active_deliveries`** - Livraisons actives avec position du livreur

### Services Flutter

#### 1. LocationService (`lib/services/location_service.dart`)
Gère les permissions GPS et la récupération de positions.

**Fonctionnalités principales :**
- Vérification et demande de permissions GPS
- Récupération de position actuelle
- Stream de positions en temps réel
- Calcul de distances et temps estimés
- Formatage des données GPS

**Méthodes clés :**
```dart
// Vérifier les permissions
static Future<bool> requestLocationPermission()

// Obtenir position actuelle
static Future<Position?> getCurrentLocation()

// Stream de positions
static Stream<Position> getLocationStream()

// Calculer distance
static double calculateDistance(Position start, Position end)
```

#### 2. TrackingService (`lib/services/tracking_service.dart`)
Gère la communication avec Supabase pour le tracking.

**Fonctionnalités principales :**
- Mise à jour des positions des livreurs
- Récupération des positions en temps réel
- Gestion des assignations livreur-commande
- Calcul de distances et temps estimés

**Méthodes clés :**
```dart
// Mettre à jour position livreur
static Future<bool> updateDriverLocation({...})

// Obtenir position livreur
static Future<Map<String, dynamic>?> getDriverLocation(String driverId)

// Assigner commande à livreur
static Future<bool> assignOrderToDriver({...})

// Obtenir livreurs en ligne
static Future<List<Map<String, dynamic>>> getOnlineDrivers()
```

#### 3. DriverTrackingService (`lib/services/driver_tracking_service.dart`)
Gère le tracking automatique côté livreur.

**Fonctionnalités principales :**
- Démarrage/arrêt automatique du tracking
- Gestion des états (en ligne/hors ligne)
- Optimisation batterie
- Mise à jour périodique des positions

**Méthodes clés :**
```dart
// Démarrer tracking
static Future<bool> startTracking(String driverId)

// Arrêter tracking
static Future<void> stopTracking()

// Mettre en pause
static Future<void> pauseTracking()

// Reprendre
static Future<void> resumeTracking()
```

### Écrans et Widgets

#### 1. OrderTrackingScreen (`lib/screens/order_tracking_screen.dart`)
Écran client pour suivre une livraison.

**Fonctionnalités :**
- Carte Google Maps avec position du livreur
- Informations de livraison en temps réel
- Boutons d'action (appeler, message)
- Mise à jour automatique toutes les 10 secondes

#### 2. DriverTrackingWidget (`lib/widgets/driver_tracking_widget.dart`)
Widget pour les livreurs pour contrôler leur tracking.

**Fonctionnalités :**
- Switch pour activer/désactiver le tracking
- Affichage des informations GPS
- Contrôles de précision
- Statistiques de tracking

## 🔄 Flux utilisateur

### Côté Livreur

1. **Connexion** → Le livreur se connecte à l'app
2. **Activation tracking** → Le livreur active le tracking GPS
3. **Permission GPS** → L'app demande l'accès GPS
4. **Stream automatique** → Les positions sont envoyées toutes les 30 secondes
5. **Assignation commande** → Le livreur reçoit une commande
6. **Livraison** → Le livreur livre et désactive le tracking

### Côté Client

1. **Commande passée** → Le client passe une commande
2. **Assignation** → Un livreur est assigné à la commande
3. **Accès suivi** → Le client peut voir le suivi de sa livraison
4. **Carte temps réel** → Position du livreur mise à jour toutes les 10 secondes
5. **Livraison terminée** → Le suivi se termine

## ⚙️ Configuration

### Permissions Android

Ajouter dans `android/app/src/main/AndroidManifest.xml` :
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### Permissions iOS

Ajouter dans `ios/Runner/Info.plist` :
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Cette app a besoin de votre position pour le suivi de livraison</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Cette app a besoin de votre position pour le suivi de livraison</string>
```

### Google Maps API Key

1. Obtenir une clé API Google Maps
2. Ajouter dans `android/app/src/main/AndroidManifest.xml` :
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="VOTRE_CLE_API" />
```

3. Ajouter dans `ios/Runner/AppDelegate.swift` :
```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("VOTRE_CLE_API")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## 🚀 Utilisation

### Pour les livreurs

1. **Intégrer le widget dans le dashboard :**
```dart
DriverTrackingWidget(
  driverId: currentDriverId,
  onTrackingStatusChanged: () {
    // Rafraîchir l'interface si nécessaire
  },
)
```

2. **Démarrer le tracking automatiquement :**
```dart
// Dans le dashboard du livreur
await DriverTrackingService.startTracking(driverId);
```

### Pour les clients

1. **Ajouter un bouton de suivi dans l'historique des commandes :**
```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(orderId: order.id),
      ),
    );
  },
  child: const Text('Suivre ma livraison'),
)
```

## 🔧 Optimisations

### Optimisation batterie

- **Précision adaptative** : Réduit la précision GPS quand la batterie est faible
- **Fréquence ajustable** : Mise à jour moins fréquente en mode économie
- **Arrêt automatique** : Arrêt du tracking quand pas de livraison active

### Optimisation réseau

- **Compression données** : Envoi uniquement des changements significatifs
- **Cache local** : Stockage temporaire si pas de réseau
- **Retry automatique** : Nouvel essai si échec d'envoi

### Sécurité

- **Chiffrement** : Positions chiffrées en transit
- **Permissions** : Accès GPS uniquement si nécessaire
- **RLS** : Row Level Security pour protéger les données

## 🐛 Dépannage

### Problèmes courants

1. **GPS non disponible**
   - Vérifier que le GPS est activé
   - Vérifier les permissions
   - Redémarrer l'app

2. **Positions non mises à jour**
   - Vérifier la connexion internet
   - Vérifier que le tracking est actif
   - Vérifier les logs de debug

3. **Batterie qui se vide rapidement**
   - Réduire la précision GPS
   - Augmenter l'intervalle de mise à jour
   - Activer le mode économie

### Logs de debug

Le système génère des logs détaillés avec des préfixes :
- `📍 [LOCATION]` - Service de géolocalisation
- `🚚 [DRIVER_TRACKING]` - Tracking côté livreur
- `📍 [TRACKING]` - Service de tracking général

## 📈 Métriques et statistiques

### Métriques collectées

- **Précision GPS** : Qualité des positions
- **Fréquence mise à jour** : Nombre de positions par minute
- **Temps de réponse** : Délai entre position et mise à jour
- **Taux de succès** : Pourcentage de positions envoyées avec succès

### Statistiques disponibles

- **Statut tracking** : Actif/inactif, en ligne/hors ligne
- **Informations GPS** : Position, précision, vitesse, direction
- **Niveau batterie** : Pourcentage de batterie restant
- **Dernière mise à jour** : Timestamp de la dernière position

## 🔮 Améliorations futures

### Fonctionnalités prévues

1. **Géocodage** : Conversion d'adresses en coordonnées GPS
2. **Notifications push** : Alertes en temps réel
3. **Historique des trajets** : Sauvegarde des parcours
4. **Optimisation d'itinéraire** : Calcul du meilleur chemin
5. **Mode hors ligne** : Fonctionnement sans internet

### Intégrations

1. **Google Maps Directions** : Calcul d'itinéraires
2. **Firebase Cloud Messaging** : Notifications push
3. **Analytics** : Statistiques d'utilisation
4. **Crashlytics** : Rapport d'erreurs

## 📝 Notes de développement

### Bonnes pratiques

1. **Gestion des permissions** : Toujours vérifier avant d'utiliser le GPS
2. **Gestion d'erreurs** : Capturer et gérer toutes les erreurs GPS
3. **Optimisation batterie** : Réduire la fréquence quand possible
4. **Sécurité** : Ne jamais stocker de positions sensibles localement

### Tests

1. **Tests unitaires** : Tester chaque service individuellement
2. **Tests d'intégration** : Tester le flux complet
3. **Tests de performance** : Vérifier l'impact sur la batterie
4. **Tests de sécurité** : Vérifier la protection des données

---

**Version** : 1.0.0  
**Dernière mise à jour** : Décembre 2024  
**Auteur** : Équipe de développement


