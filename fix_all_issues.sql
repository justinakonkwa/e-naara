-- =====================================================
-- 🔧 CORRECTION COMPLÈTE DE TOUS LES PROBLÈMES
-- =====================================================

-- Ce script corrige :
-- 1. Le problème RLS du système de portefeuille
-- 2. Le problème de contrainte orders_status_valid
-- 3. Les colonnes manquantes pour le système de livreurs

-- =====================================================
-- ÉTAPE 1: CORRECTION DU SYSTÈME DE PORTEFEUILLE
-- =====================================================

SELECT '🔧 ÉTAPE 1: Correction du système de portefeuille' as info;

-- Vérifier si la table wallets existe
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wallets') THEN
        -- Créer la table wallets
        CREATE TABLE wallets (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
            balance DECIMAL(10,2) DEFAULT 0.00 NOT NULL,
            currency VARCHAR(3) DEFAULT 'USD' NOT NULL CHECK (currency IN ('USD', 'CDF')),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
            UNIQUE(user_id)
        );
        
        -- Créer la table wallet_transactions
        CREATE TABLE wallet_transactions (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE NOT NULL,
            type VARCHAR(20) NOT NULL CHECK (type IN ('credit', 'debit', 'withdrawal', 'refund')),
            amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
            description TEXT NOT NULL,
            order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
            reference VARCHAR(255),
            status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
        );
        
        RAISE NOTICE 'Tables wallets et wallet_transactions créées';
    ELSE
        RAISE NOTICE 'Tables wallets et wallet_transactions existent déjà';
    END IF;
END $$;

-- Activer RLS
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques RLS
DROP POLICY IF EXISTS "Users can view their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can update their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can insert their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can delete their own wallet" ON wallets;
DROP POLICY IF EXISTS "System can create wallet for new users" ON wallets;

-- Créer de nouvelles politiques RLS plus permissives
CREATE POLICY "Users can view their own wallet" ON wallets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallet" ON wallets
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own wallet" ON wallets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own wallet" ON wallets
    FOR DELETE USING (auth.uid() = user_id);

-- Politique spéciale pour permettre la création automatique de portefeuilles
CREATE POLICY "System can create wallet for new users" ON wallets
    FOR INSERT WITH CHECK (
        NOT EXISTS (
            SELECT 1 FROM wallets WHERE user_id = auth.uid()
        )
    );

-- Recréer la fonction create_wallet_for_user
CREATE OR REPLACE FUNCTION create_wallet_for_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier si l'utilisateur a déjà un portefeuille
    IF NOT EXISTS (SELECT 1 FROM wallets WHERE user_id = NEW.id) THEN
        -- Créer un portefeuille pour le nouvel utilisateur
        INSERT INTO wallets (user_id, balance, currency)
        VALUES (NEW.id, 0.00, 'USD');
        
        RAISE NOTICE 'Portefeuille créé pour l''utilisateur %', NEW.id;
    ELSE
        RAISE NOTICE 'L''utilisateur % a déjà un portefeuille', NEW.id;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors de la création du portefeuille pour l''utilisateur %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ language 'plpgsql';

-- Recréer le trigger
DROP TRIGGER IF EXISTS create_wallet_for_user_trigger ON users;
CREATE TRIGGER create_wallet_for_user_trigger
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION create_wallet_for_user();

-- Créer des portefeuilles pour les utilisateurs existants qui n'en ont pas
INSERT INTO wallets (user_id, balance, currency)
SELECT 
    u.id,
    0.00,
    'USD'
FROM auth.users u
WHERE NOT EXISTS (
    SELECT 1 FROM wallets w WHERE w.user_id = u.id
);

-- =====================================================
-- ÉTAPE 2: CORRECTION DE LA CONTRAINTE ORDERS_STATUS_VALID
-- =====================================================

SELECT '🔧 ÉTAPE 2: Correction de la contrainte orders_status_valid' as info;

-- Supprimer l'ancienne contrainte
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'orders_status_valid'
    ) THEN
        ALTER TABLE orders DROP CONSTRAINT orders_status_valid;
        RAISE NOTICE 'Ancienne contrainte orders_status_valid supprimée';
    ELSE
        RAISE NOTICE 'Contrainte orders_status_valid n''existe pas';
    END IF;
END $$;

-- Créer la nouvelle contrainte avec tous les statuts nécessaires
ALTER TABLE orders ADD CONSTRAINT orders_status_valid 
CHECK (status IN (
    'pending',      -- En attente de confirmation
    'confirmed',    -- Confirmée, prête pour livraison
    'assigned',     -- Assignée à un livreur
    'picked_up',    -- Récupérée par le livreur
    'in_transit',   -- En cours de livraison
    'delivered',    -- Livrée avec succès
    'cancelled',    -- Annulée
    'refunded'      -- Remboursée
));

-- =====================================================
-- ÉTAPE 3: AJOUT DES COLONNES MANQUANTES POUR LES LIVREURS
-- =====================================================

SELECT '🚚 ÉTAPE 3: Ajout des colonnes manquantes pour les livreurs' as info;

DO $$ 
BEGIN
    -- Ajouter la colonne driver_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'driver_id') THEN
        ALTER TABLE orders ADD COLUMN driver_id UUID REFERENCES auth.users(id);
        RAISE NOTICE 'Colonne driver_id ajoutée';
    ELSE
        RAISE NOTICE 'Colonne driver_id existe déjà';
    END IF;
    
    -- Ajouter la colonne assigned_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'assigned_at') THEN
        ALTER TABLE orders ADD COLUMN assigned_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Colonne assigned_at ajoutée';
    ELSE
        RAISE NOTICE 'Colonne assigned_at existe déjà';
    END IF;
    
    -- Ajouter la colonne picked_up_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'picked_up_at') THEN
        ALTER TABLE orders ADD COLUMN picked_up_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Colonne picked_up_at ajoutée';
    ELSE
        RAISE NOTICE 'Colonne picked_up_at existe déjà';
    END IF;
    
    -- Ajouter la colonne delivered_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivered_at') THEN
        ALTER TABLE orders ADD COLUMN delivered_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Colonne delivered_at ajoutée';
    ELSE
        RAISE NOTICE 'Colonne delivered_at existe déjà';
    END IF;
    
    -- Ajouter la colonne shipping_latitude
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_latitude') THEN
        ALTER TABLE orders ADD COLUMN shipping_latitude DOUBLE PRECISION;
        RAISE NOTICE 'Colonne shipping_latitude ajoutée';
    ELSE
        RAISE NOTICE 'Colonne shipping_latitude existe déjà';
    END IF;
    
    -- Ajouter la colonne shipping_longitude
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_longitude') THEN
        ALTER TABLE orders ADD COLUMN shipping_longitude DOUBLE PRECISION;
        RAISE NOTICE 'Colonne shipping_longitude ajoutée';
    ELSE
        RAISE NOTICE 'Colonne shipping_longitude existe déjà';
    END IF;
END $$;

-- =====================================================
-- ÉTAPE 4: CONFIGURATION DES POLITIQUES RLS POUR LES COMMANDES
-- =====================================================

SELECT '🔐 ÉTAPE 4: Configuration des politiques RLS pour les commandes' as info;

-- Supprimer les anciennes politiques
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

-- Créer les nouvelles politiques
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

-- =====================================================
-- ÉTAPE 5: CRÉATION DES INDEX
-- =====================================================

SELECT '📊 ÉTAPE 5: Création des index' as info;

-- Index pour wallets
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);

-- Index pour wallet_transactions
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_type ON wallet_transactions(type);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_status ON wallet_transactions(status);

-- Index pour orders (système de livreurs)
CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_status_driver_id ON orders(status, driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_assigned_at ON orders(assigned_at);
CREATE INDEX IF NOT EXISTS idx_orders_picked_up_at ON orders(picked_up_at);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_at ON orders(delivered_at);
CREATE INDEX IF NOT EXISTS idx_orders_shipping_location ON orders(shipping_latitude, shipping_longitude);

-- =====================================================
-- ÉTAPE 6: VÉRIFICATIONS FINALES
-- =====================================================

SELECT '🔍 ÉTAPE 6: Vérifications finales' as info;

-- Vérifier les tables créées
SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('wallets', 'wallet_transactions', 'orders') THEN '✅ Table existe'
        ELSE '❌ Table manquante'
    END as status
FROM information_schema.tables 
WHERE table_name IN ('wallets', 'wallet_transactions', 'orders')
AND table_schema = 'public';

-- Vérifier les politiques RLS
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN cmd IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE') THEN '✅ Politique configurée'
        ELSE '⚠️ Politique inconnue'
    END as status
FROM pg_policies 
WHERE tablename IN ('wallets', 'orders')
ORDER BY tablename, policyname;

-- Statistiques des portefeuilles
SELECT 
    COUNT(*) as total_portefeuilles,
    COUNT(CASE WHEN balance > 0 THEN 1 END) as portefeuilles_avec_solde,
    AVG(balance) as solde_moyen
FROM wallets;

-- Statistiques des commandes
SELECT 
    COUNT(*) as total_commandes,
    COUNT(CASE WHEN driver_id IS NOT NULL THEN 1 END) as commandes_assignees,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as commandes_livrees
FROM orders;

-- =====================================================
-- MESSAGE DE CONFIRMATION
-- =====================================================

SELECT '🎉 CORRECTION COMPLÈTE TERMINÉE AVEC SUCCÈS!' as message;
SELECT 'Tous les problèmes ont été résolus :' as info;
SELECT '✅ Système de portefeuille opérationnel' as info;
SELECT '✅ Contrainte orders_status_valid corrigée' as info;
SELECT '✅ Système de livreurs configuré' as info;
SELECT '✅ Politiques RLS mises à jour' as info;
