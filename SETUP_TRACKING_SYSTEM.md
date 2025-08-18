# 🚀 Guide de Configuration du Système de Tracking

## 📋 Prérequis

### 1. **Google Maps API Key**
1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un projet ou sélectionnez un projet existant
3. Activez l'API "Maps SDK for Android"
4. Créez une clé API
5. Remplacez `YOUR_GOOGLE_MAPS_API_KEY` dans `android/app/src/main/AndroidManifest.xml`

### 2. **Base de données Supabase**
Exécutez le script SQL dans votre base de données Supabase :

```sql
-- Copier et exécuter le contenu de tracking_system_setup.sql
```

## 🔧 Configuration étape par étape

### **Étape 1 : Configurer Google Maps**

1. **Ouvrir le fichier** `android/app/src/main/AndroidManifest.xml`
2. **Remplacer** la ligne :
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY" />
   ```
3. **Par votre vraie clé API** :
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIzaSyBvotre_vraie_cle_api_ici" />
   ```

### **Étape 2 : Créer les tables de tracking**

1. **Ouvrir Supabase Dashboard**
2. **Aller dans SQL Editor**
3. **Copier et exécuter** le contenu de `tracking_system_setup.sql`

### **Étape 3 : Vérifier les permissions**

Assurez-vous que les politiques RLS sont créées :
- `driver_locations` : Tables pour les positions GPS
- `delivery_assignments` : Tables pour les assignations livreur-commande

## 🧪 Test du système

### **Test côté livreur :**
1. Connectez-vous avec un compte livreur
2. Allez dans le dashboard livreur
3. Activez le widget de tracking GPS
4. Vérifiez que la position se met à jour

### **Test côté client :**
1. Connectez-vous avec un compte client
2. Passez une commande
3. Allez dans l'historique des commandes
4. Cliquez sur "Suivre ma livraison"
5. Vérifiez que la carte s'affiche

## 🔍 Dépannage

### **Erreur Google Maps :**
```
Authorization failure. Please see https://developers.google.com/maps/documentation/android-sdk/start
```
**Solution :** Vérifiez que votre clé API est correcte et que l'API Maps SDK for Android est activée.

### **Erreur permissions base de données :**
```
permission denied for table users
```
**Solution :** Exécutez le script SQL `tracking_system_setup.sql` dans Supabase.

### **Erreur de connexion :**
```
Failed to start Dart Development Service
```
**Solution :** Redémarrez l'application avec `flutter run --hot`

## 📱 Fonctionnalités disponibles

### **Côté Livreur :**
- ✅ Activation/désactivation du tracking GPS
- ✅ Affichage des informations de position
- ✅ Contrôles de précision GPS
- ✅ Statut en ligne/hors ligne

### **Côté Client :**
- ✅ Carte Google Maps avec position du livreur
- ✅ Informations de livraison en temps réel
- ✅ Boutons d'action (appeler, message)
- ✅ Mise à jour automatique

## 🎯 Prochaines étapes

1. **Configurer les notifications push** pour les mises à jour de livraison
2. **Ajouter la géolocalisation des adresses** pour une meilleure précision
3. **Implémenter les appels et messages** dans l'interface
4. **Optimiser la consommation batterie** pour les longues livraisons

---

**✅ Le système est maintenant prêt à être utilisé !**


