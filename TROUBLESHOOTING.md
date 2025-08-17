# 🔧 Guide de dépannage - Problèmes de connexion Supabase

## Erreur "Load failed (api.supabase.com)"

### Causes possibles et solutions :

#### 1. **Problème de connexion internet**
- ✅ **Vérifier** : Votre connexion internet fonctionne
- ✅ **Tester** : Ouvrir un site web dans le navigateur
- ✅ **Solution** : Redémarrer le routeur si nécessaire

#### 2. **Problème de configuration Supabase**
- ✅ **Vérifier** : Les clés dans `lib/config/supabase_config.dart`
- ✅ **Vérifier** : Le projet Supabase est actif
- ✅ **Solution** : Vérifier le dashboard Supabase

#### 3. **Problème de RLS (Row Level Security)**
- ✅ **Vérifier** : Les politiques RLS sont configurées
- ✅ **Vérifier** : L'utilisateur a les bonnes permissions
- ✅ **Solution** : Exécuter les scripts SQL de configuration

#### 4. **Problème de tables manquantes**
- ✅ **Vérifier** : Toutes les tables existent
- ✅ **Vérifier** : Les colonnes sont correctes
- ✅ **Solution** : Exécuter les scripts de création de tables

### Étapes de diagnostic :

#### Étape 1 : Utiliser le diagnostic intégré
1. Ouvrir l'écran Messages
2. Cliquer sur l'icône 🐛 (bug) dans la barre d'outils
3. Vérifier les résultats du diagnostic

#### Étape 2 : Vérifier la configuration
```dart
// Dans le code, vérifier :
SupabaseDiagnostic.checkConfiguration();
```

#### Étape 3 : Tester la connexion
```dart
// Tester la connexion basique
final isConnected = await SupabaseDiagnostic.testBasicConnection();
```

#### Étape 4 : Vérifier les tables
```dart
// Tester l'accès aux tables
final usersAccessible = await SupabaseDiagnostic.testUsersTable();
final chatsAccessible = await SupabaseDiagnostic.testChatsTable();
```

### Solutions rapides :

#### Solution 1 : Redémarrer l'application
```bash
flutter clean
flutter pub get
flutter run
```

#### Solution 2 : Vérifier Supabase Dashboard
1. Aller sur https://supabase.com/dashboard
2. Sélectionner votre projet
3. Vérifier que le projet est actif
4. Vérifier les logs d'API

#### Solution 3 : Vérifier les clés API
1. Dans Supabase Dashboard → Settings → API
2. Copier l'URL et la clé anonyme
3. Mettre à jour `lib/config/supabase_config.dart`

#### Solution 4 : Vérifier les politiques RLS
```sql
-- Exécuter dans l'éditeur SQL de Supabase
SELECT * FROM pg_policies WHERE tablename = 'users';
SELECT * FROM pg_policies WHERE tablename = 'chats';
```

### Messages d'erreur courants :

#### "Load failed (api.supabase.com)"
- **Cause** : Problème de connexion réseau ou configuration
- **Solution** : Utiliser le diagnostic intégré

#### "invalid input syntax for type uuid"
- **Cause** : Données corrompues dans la base
- **Solution** : Exécuter `fix_chat_data_with_auth.sql`

#### "foreign key constraint violation"
- **Cause** : Référence à un utilisateur inexistant
- **Solution** : Exécuter `fix_chat_data_with_auth.sql`

#### "table does not exist"
- **Cause** : Tables non créées
- **Solution** : Exécuter les scripts de création de tables

### Contact et support :

Si les problèmes persistent :
1. Vérifier les logs dans la console Flutter
2. Utiliser le diagnostic intégré
3. Vérifier le dashboard Supabase
4. Consulter la documentation Supabase

### Commandes utiles :

```bash
# Nettoyer et reconstruire
flutter clean
flutter pub get
flutter run

# Vérifier les dépendances
flutter doctor
flutter pub deps

# Analyser le code
flutter analyze
```


