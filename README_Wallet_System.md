# Système de Portefeuille pour Utilisateurs

## Vue d'ensemble

Le système de portefeuille permet à tous les utilisateurs de gérer leurs gains provenant des ventes de produits. Tous les utilisateurs (clients, livreurs, administrateurs) peuvent vendre des produits et avoir un portefeuille. Chaque utilisateur a un portefeuille automatiquement créé lors de son inscription, et les gains sont automatiquement ajoutés lorsque les commandes sont livrées.

## Fonctionnalités

### Pour les Utilisateurs

1. **Visualisation du solde** : Affichage du solde actuel en temps réel
2. **Historique des transactions** : Liste complète de toutes les transactions
3. **Statistiques** : Vue d'ensemble des gains totaux, retraits et transactions
4. **Retrait de fonds** : Possibilité de retirer de l'argent du portefeuille
5. **Notifications** : Alertes pour les nouvelles transactions

### Fonctionnalités Automatiques

1. **Création automatique** : Un portefeuille est créé automatiquement pour chaque nouvel utilisateur
2. **Crédit automatique** : L'argent est ajouté automatiquement lors de la livraison des commandes
3. **Commission** : 90% du montant de la vente va à l'utilisateur, 10% de commission pour la plateforme
4. **Accès universel** : Tous les utilisateurs (clients, livreurs, administrateurs) peuvent vendre et accéder à leur portefeuille

## Structure de la Base de Données

### Table `wallets`
- `id` : Identifiant unique du portefeuille
- `user_id` : Référence vers l'utilisateur
- `balance` : Solde actuel du portefeuille
- `currency` : Devise (USD par défaut, supporte USD et CDF)
- `created_at` : Date de création
- `updated_at` : Date de dernière mise à jour

### Table `wallet_transactions`
- `id` : Identifiant unique de la transaction
- `wallet_id` : Référence vers le portefeuille
- `type` : Type de transaction (credit, debit, withdrawal, refund)
- `amount` : Montant de la transaction
- `description` : Description de la transaction
- `order_id` : Référence vers la commande (optionnel)
- `reference` : Référence externe (optionnel)
- `status` : Statut de la transaction (pending, completed, failed, cancelled)
- `created_at` : Date de création de la transaction

## Installation

### 1. Exécuter le script SQL

Exécutez le fichier `setup_wallet_tables.sql` dans votre base de données Supabase :

```sql
-- Copier et exécuter le contenu de setup_wallet_tables.sql
```

### 2. Vérifier les dépendances

Assurez-vous que la dépendance `intl` est ajoutée dans `pubspec.yaml` :

```yaml
dependencies:
  intl: ^0.19.0
```

### 3. Redémarrer l'application

```bash
flutter pub get
flutter run
```

## Utilisation

### Accès au Portefeuille

1. Connectez-vous en tant que vendeur
2. Le portefeuille apparaît automatiquement dans la navigation
3. Cliquez sur l'icône "Portefeuille" pour accéder à l'écran

### Interface Utilisateur

#### Écran Principal
- **Carte de solde** : Affichage du solde actuel avec un design moderne
- **Statistiques** : Nombre de transactions et montants en attente
- **Bouton de retrait** : Pour retirer des fonds

#### Historique des Transactions
- Liste chronologique des transactions
- Indicateurs visuels pour les crédits (vert) et débits (rouge)
- Statuts colorés pour chaque transaction
- Informations détaillées (date, montant, description)

### Retrait de Fonds

1. Cliquez sur "Retirer des fonds"
2. Entrez le montant souhaité
3. Confirmez la transaction
4. Le montant est déduit du solde et une transaction est créée

## Sécurité

### Politiques RLS (Row Level Security)
- Les utilisateurs ne peuvent voir que leur propre portefeuille
- Les transactions sont isolées par utilisateur
- Validation des montants et des statuts

### Validation
- Vérification du solde avant retrait
- Validation des montants positifs
- Contrôle des statuts de transaction

## Intégration avec les Commandes

### Déclenchement Automatique
- Lorsqu'une commande passe au statut "delivered"
- Le système calcule automatiquement la commission
- L'argent est ajouté au portefeuille du vendeur
- Une transaction est créée avec les détails

### Commission
- **90%** pour le vendeur
- **10%** de commission pour la plateforme
- Calcul automatique basé sur le montant total de la commande

## Gestion des Erreurs

### Erreurs Courantes
- **Solde insuffisant** : Impossible de retirer plus que le solde disponible
- **Transaction échouée** : Retry automatique ou notification manuelle
- **Connexion perdue** : Gestion des erreurs réseau

### Logs et Monitoring
- Toutes les transactions sont loggées
- Suivi des erreurs dans la console
- Notifications utilisateur en cas de problème

## Personnalisation

### Modification de la Commission
Pour changer le taux de commission, modifiez la variable dans la fonction SQL :

```sql
commission_rate DECIMAL(5,4) := 0.90; -- 90% pour le vendeur
```

### Devises Supportées
- **USD** : Dollar américain (devise par défaut)
- **CDF** : Franc congolais

### Ajout de Nouvelles Devises
1. Modifiez la contrainte CHECK dans la table `wallets`
2. Ajoutez les nouvelles devises supportées
3. Mettez à jour l'interface utilisateur

### Personnalisation de l'Interface
- Modifiez les couleurs dans `wallet_screen.dart`
- Ajoutez de nouveaux indicateurs statistiques
- Personnalisez les messages et descriptions

## Support et Maintenance

### Vérifications Régulières
- Contrôle de l'intégrité des données
- Vérification des transactions en attente
- Monitoring des performances

### Sauvegarde
- Sauvegarde automatique des données de portefeuille
- Récupération en cas de problème
- Historique des modifications

## API Endpoints (Futur)

### Endpoints Prévisionnels
- `GET /api/wallet/balance` : Obtenir le solde
- `GET /api/wallet/transactions` : Liste des transactions
- `POST /api/wallet/withdraw` : Effectuer un retrait
- `GET /api/wallet/stats` : Statistiques du portefeuille

## Conclusion

Le système de portefeuille offre une solution complète pour la gestion financière des vendeurs, avec une interface intuitive et des fonctionnalités automatiques pour simplifier les opérations quotidiennes.
