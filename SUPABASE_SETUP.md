# 🚀 Configuration Supabase pour ShopFlow

Ce guide vous explique comment configurer Supabase pour votre application ShopFlow.

## 📋 Prérequis

1. Un compte Supabase (gratuit sur [supabase.com](https://supabase.com))
2. Flutter SDK installé
3. L'application ShopFlow configurée

## 🔧 Étapes de configuration

### 1. Créer un projet Supabase

1. Connectez-vous à [supabase.com](https://supabase.com)
2. Cliquez sur "New Project"
3. Choisissez votre organisation
4. Donnez un nom à votre projet (ex: "shopflow")
5. Créez un mot de passe pour la base de données
6. Choisissez une région proche de vos utilisateurs
7. Cliquez sur "Create new project"

### 2. Configurer la base de données

1. Dans votre projet Supabase, allez dans **SQL Editor**
2. Copiez le contenu du fichier `supabase_schema.sql`
3. Collez-le dans l'éditeur SQL
4. Cliquez sur **Run** pour exécuter le script

Ce script va créer :
- ✅ Toutes les tables nécessaires
- ✅ Les index pour les performances
- ✅ Les politiques de sécurité (RLS)
- ✅ Les triggers automatiques
- ✅ Les données d'exemple (catégories et codes promo)

### 3. Récupérer les clés d'API

1. Dans votre projet Supabase, allez dans **Settings** > **API**
2. Copiez :
   - **Project URL** (ex: `https://your-project.supabase.co`)
   - **anon public** key (commence par `eyJ...`)

### 4. Configurer l'application Flutter

1. Ouvrez le fichier `lib/config/supabase_config.dart`
2. Remplacez les valeurs par vos clés Supabase :

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'VOTRE_URL_SUPABASE';
  static const String supabaseAnonKey = 'VOTRE_CLE_ANONYME_SUPABASE';
  // ...
}
```

### 5. Installer les dépendances

Exécutez dans votre terminal :

```bash
flutter pub get
```

### 6. Tester la connexion

1. Lancez l'application : `flutter run`
2. Créez un compte ou connectez-vous
3. Vérifiez que les données se chargent correctement

## 🗄️ Structure de la base de données

### Tables principales :

- **users** : Profils utilisateurs
- **categories** : Catégories de produits
- **products** : Produits du catalogue
- **cart_items** : Éléments du panier
- **orders** : Commandes
- **order_items** : Éléments de commande
- **reviews** : Avis produits
- **wishlist** : Liste de souhaits
- **promo_codes** : Codes de réduction

### Sécurité :

- ✅ **Row Level Security (RLS)** activé sur toutes les tables
- ✅ **Politiques de sécurité** pour protéger les données
- ✅ **Authentification** via Supabase Auth
- ✅ **Autorisations** basées sur l'utilisateur connecté

## 🔐 Authentification

L'application utilise Supabase Auth avec :
- Inscription par email/mot de passe
- Connexion sécurisée
- Gestion automatique des sessions
- Protection des routes

## 📱 Fonctionnalités intégrées

### ✅ Authentification
- Inscription/Connexion
- Gestion des sessions
- Profils utilisateurs

### ✅ Catalogue produits
- Affichage des produits
- Recherche et filtres
- Catégories et sous-catégories
- Images et descriptions

### ✅ Panier
- Ajout/suppression de produits
- Gestion des quantités
- Sauvegarde automatique
- Codes promo

### ✅ Commandes
- Création de commandes
- Historique des achats
- Suivi des statuts

### ✅ Liste de souhaits
- Ajout/suppression
- Synchronisation
- Affichage personnalisé

## 🚨 Dépannage

### Erreur de connexion
- Vérifiez vos clés Supabase dans `supabase_config.dart`
- Assurez-vous que votre projet est actif
- Vérifiez votre connexion internet

### Erreur de base de données
- Vérifiez que le script SQL a été exécuté
- Contrôlez les politiques RLS
- Vérifiez les permissions utilisateur

### Erreur d'authentification
- Vérifiez que Supabase Auth est activé
- Contrôlez les paramètres d'authentification
- Vérifiez les emails de confirmation

## 🔄 Migration des données

Si vous avez des données existantes :

1. Exportez vos données actuelles
2. Adaptez le format pour correspondre au schéma Supabase
3. Importez via l'interface Supabase ou SQL
4. Vérifiez l'intégrité des données

## 📈 Monitoring

Dans Supabase, vous pouvez surveiller :
- **Logs** : Requêtes et erreurs
- **Analytics** : Utilisation de l'API
- **Database** : Performance des requêtes
- **Auth** : Connexions et inscriptions

## 🆘 Support

En cas de problème :
1. Vérifiez les logs dans Supabase
2. Consultez la [documentation Supabase](https://supabase.com/docs)
3. Vérifiez les erreurs dans la console Flutter
4. Testez avec des données d'exemple

---

**🎉 Félicitations !** Votre application ShopFlow est maintenant connectée à Supabase et prête à être utilisée en production !
