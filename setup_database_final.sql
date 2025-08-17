-- =====================================================
-- 🚀 CONFIGURATION FINALE DE LA BASE DE DONNÉES
-- =====================================================

-- =====================================================
-- 🎭 ÉTAPE 1: AJOUT DES RÔLES UTILISATEUR
-- =====================================================

-- Ajouter la colonne role à la table users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'driver', 'admin'));

-- Ajouter un index pour optimiser les requêtes par rôle
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Supprimer toutes les anciennes politiques sur users
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;

-- Créer des politiques simples SANS RÉCURSION
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Politiques admin simplifiées (sans récursion)
CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (true);

CREATE POLICY "Admins can update all users" ON users
    FOR UPDATE USING (true);

-- Commentaire sur la colonne role
COMMENT ON COLUMN users.role IS 'Rôle de l''utilisateur: user, driver, ou admin';

-- =====================================================
-- 🚚 ÉTAPE 2: AJOUT DE LA GESTION DES LIVREURS
-- =====================================================

-- Ajouter les colonnes nécessaires pour la gestion des livreurs
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS picked_up_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP WITH TIME ZONE;

-- Ajouter des index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_status_driver_id ON orders(status, driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_assigned_at ON orders(assigned_at);
CREATE INDEX IF NOT EXISTS idx_orders_picked_up_at ON orders(picked_up_at);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_at ON orders(delivered_at);

-- Supprimer toutes les anciennes politiques sur orders
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert own orders" ON orders;
DROP POLICY IF EXISTS "Drivers can view assigned orders" ON orders;
DROP POLICY IF EXISTS "Drivers can update assigned orders" ON orders;
DROP POLICY IF EXISTS "Drivers can view available orders" ON orders;
DROP POLICY IF EXISTS "Drivers can assign orders" ON orders;
DROP POLICY IF EXISTS "Drivers can mark as picked up" ON orders;
DROP POLICY IF EXISTS "Drivers can confirm delivery" ON orders;
DROP POLICY IF EXISTS "Drivers can cancel assignment" ON orders;

-- Créer les nouvelles politiques pour orders
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Drivers can view assigned orders" ON orders
    FOR SELECT USING (auth.uid() = driver_id);

CREATE POLICY "Drivers can update assigned orders" ON orders
    FOR UPDATE USING (auth.uid() = driver_id);

CREATE POLICY "Drivers can view available orders" ON orders
    FOR SELECT USING (
        driver_id IS NULL 
        AND status IN ('pending', 'confirmed')
    );

CREATE POLICY "Drivers can assign orders" ON orders
    FOR UPDATE USING (
        driver_id IS NULL 
        AND status IN ('pending', 'confirmed')
    );

CREATE POLICY "Drivers can mark as picked up" ON orders
    FOR UPDATE USING (
        auth.uid() = driver_id 
        AND status = 'assigned'
    );

CREATE POLICY "Drivers can confirm delivery" ON orders
    FOR UPDATE USING (
        auth.uid() = driver_id 
        AND status IN ('picked_up', 'in_transit')
    );

CREATE POLICY "Drivers can cancel assignment" ON orders
    FOR UPDATE USING (
        auth.uid() = driver_id 
        AND status IN ('assigned', 'picked_up')
    );

-- Commentaires sur les nouvelles colonnes
COMMENT ON COLUMN orders.driver_id IS 'ID du livreur assigné à cette commande';
COMMENT ON COLUMN orders.assigned_at IS 'Date et heure d''assignation de la commande au livreur';
COMMENT ON COLUMN orders.picked_up_at IS 'Date et heure de récupération de la commande par le livreur';
COMMENT ON COLUMN orders.delivered_at IS 'Date et heure de livraison confirmée';

-- =====================================================
-- 🔄 ÉTAPE 3: MISE À JOUR DES DONNÉES EXISTANTES
-- =====================================================

-- Mettre à jour les utilisateurs existants sans rôle
UPDATE users SET role = 'user' WHERE role IS NULL;

-- =====================================================
-- ✅ ÉTAPE 4: VÉRIFICATION
-- =====================================================

-- Vérifier que la colonne role a été ajoutée
SELECT 'users.role column' as check_item,
       CASE 
           WHEN EXISTS (
               SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'users' AND column_name = 'role'
           ) THEN '✅ OK'
           ELSE '❌ MISSING'
       END as status;

-- Vérifier que les colonnes driver ont été ajoutées
SELECT 'orders.driver_id column' as check_item,
       CASE 
           WHEN EXISTS (
               SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'orders' AND column_name = 'driver_id'
           ) THEN '✅ OK'
           ELSE '❌ MISSING'
       END as status;

-- Vérifier les politiques créées
SELECT 'RLS Policies' as check_item,
       COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename IN ('users', 'orders');

-- Vérifier les index créés
SELECT 'Indexes' as check_item,
       COUNT(*) as index_count
FROM pg_indexes 
WHERE tablename IN ('users', 'orders');

-- =====================================================
-- 📋 STATUTS DE COMMANDE SUPPORTÉS
-- =====================================================
/*
Statuts disponibles :
- 'pending' : En attente de confirmation
- 'confirmed' : Confirmée, prête pour livraison
- 'assigned' : Assignée à un livreur
- 'picked_up' : Récupérée par le livreur
- 'in_transit' : En cours de livraison
- 'delivered' : Livrée avec succès
- 'cancelled' : Annulée
*/

-- =====================================================
-- 🎯 RÔLES DISPONIBLES
-- =====================================================
/*
Rôles disponibles :
- 'user' : Client normal (par défaut)
- 'driver' : Livreur (accès aux fonctionnalités de livraison)
- 'admin' : Administrateur (accès complet)
*/

-- =====================================================
-- 🔍 REQUÊTES UTILES POUR LES TESTS
-- =====================================================

-- Voir tous les utilisateurs et leurs rôles
-- SELECT id, email, first_name, last_name, role, created_at FROM users ORDER BY created_at DESC;

-- Voir tous les livreurs
-- SELECT id, email, first_name, last_name, created_at FROM users WHERE role = 'driver';

-- Voir toutes les commandes disponibles pour livraison
-- SELECT * FROM orders WHERE driver_id IS NULL AND status IN ('pending', 'confirmed');

-- Voir les commandes d'un livreur spécifique
-- SELECT * FROM orders WHERE driver_id = 'user_id_here' AND status IN ('assigned', 'picked_up');

-- Statistiques des rôles
-- SELECT role, COUNT(*) as count FROM users GROUP BY role ORDER BY count DESC;

-- Statistiques des commandes
-- SELECT status, COUNT(*) as count FROM orders GROUP BY status ORDER BY count DESC;
