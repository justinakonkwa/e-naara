-- =====================================================
-- 🚚 CORRECTION COMPLÈTE DU SYSTÈME DE LIVREURS
-- =====================================================

-- Ce script corrige tous les problèmes liés au système de livreurs
-- 1. Corrige la contrainte orders_status_valid
-- 2. Ajoute les colonnes manquantes pour la gestion des livreurs
-- 3. Configure les politiques RLS appropriées

-- =====================================================
-- ÉTAPE 1: CORRECTION DE LA CONTRAINTE ORDERS_STATUS_VALID
-- =====================================================

SELECT '🔧 ÉTAPE 1: Correction de la contrainte orders_status_valid' as info;

-- Vérifier la contrainte actuelle
SELECT 'Contrainte actuelle:' as info;
SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_name = 'orders_status_valid';

-- Supprimer l'ancienne contrainte
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'orders_status_valid'
    ) THEN
        ALTER TABLE orders DROP CONSTRAINT orders_status_valid;
        RAISE NOTICE '✅ Ancienne contrainte orders_status_valid supprimée';
    ELSE
        RAISE NOTICE 'ℹ️ Contrainte orders_status_valid n''existe pas';
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

SELECT '✅ Nouvelle contrainte orders_status_valid créée' as info;

-- =====================================================
-- ÉTAPE 2: AJOUT DES COLONNES MANQUANTES
-- =====================================================

SELECT '🚚 ÉTAPE 2: Ajout des colonnes manquantes pour la gestion des livreurs' as info;

DO $$ 
BEGIN
    -- Ajouter la colonne driver_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'driver_id') THEN
        ALTER TABLE orders ADD COLUMN driver_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne driver_id ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne driver_id existe déjà';
    END IF;
    
    -- Ajouter la colonne assigned_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'assigned_at') THEN
        ALTER TABLE orders ADD COLUMN assigned_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne assigned_at ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne assigned_at existe déjà';
    END IF;
    
    -- Ajouter la colonne picked_up_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'picked_up_at') THEN
        ALTER TABLE orders ADD COLUMN picked_up_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne picked_up_at ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne picked_up_at existe déjà';
    END IF;
    
    -- Ajouter la colonne delivered_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivered_at') THEN
        ALTER TABLE orders ADD COLUMN delivered_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne delivered_at ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne delivered_at existe déjà';
    END IF;
    
    -- Ajouter la colonne shipping_latitude
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_latitude') THEN
        ALTER TABLE orders ADD COLUMN shipping_latitude DOUBLE PRECISION;
        RAISE NOTICE '✅ Colonne shipping_latitude ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne shipping_latitude existe déjà';
    END IF;
    
    -- Ajouter la colonne shipping_longitude
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_longitude') THEN
        ALTER TABLE orders ADD COLUMN shipping_longitude DOUBLE PRECISION;
        RAISE NOTICE '✅ Colonne shipping_longitude ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne shipping_longitude existe déjà';
    END IF;
END $$;

-- =====================================================
-- ÉTAPE 3: CRÉATION DES INDEX
-- =====================================================

SELECT '📊 ÉTAPE 3: Création des index pour optimiser les performances' as info;

CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_status_driver_id ON orders(status, driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_assigned_at ON orders(assigned_at);
CREATE INDEX IF NOT EXISTS idx_orders_picked_up_at ON orders(picked_up_at);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_at ON orders(delivered_at);
CREATE INDEX IF NOT EXISTS idx_orders_shipping_location ON orders(shipping_latitude, shipping_longitude);

SELECT '✅ Index créés' as info;

-- =====================================================
-- ÉTAPE 4: CONFIGURATION DES POLITIQUES RLS
-- =====================================================

SELECT '🔐 ÉTAPE 4: Configuration des politiques RLS' as info;

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

SELECT '✅ Politiques RLS configurées' as info;

-- =====================================================
-- ÉTAPE 5: AJOUT DES COMMENTAIRES
-- =====================================================

SELECT '📝 ÉTAPE 5: Ajout des commentaires' as info;

COMMENT ON COLUMN orders.driver_id IS 'ID du livreur assigné à cette commande';
COMMENT ON COLUMN orders.assigned_at IS 'Date et heure d''assignation de la commande au livreur';
COMMENT ON COLUMN orders.picked_up_at IS 'Date et heure de récupération de la commande par le livreur';
COMMENT ON COLUMN orders.delivered_at IS 'Date et heure de livraison confirmée';
COMMENT ON COLUMN orders.shipping_latitude IS 'Latitude de l''adresse de livraison';
COMMENT ON COLUMN orders.shipping_longitude IS 'Longitude de l''adresse de livraison';

-- =====================================================
-- ÉTAPE 6: VÉRIFICATIONS FINALES
-- =====================================================

SELECT '🔍 ÉTAPE 6: Vérifications finales' as info;

-- Vérifier la structure finale
SELECT 'Structure finale de la table orders:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Vérifier la contrainte
SELECT 'Contrainte orders_status_valid:' as info;
SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_name = 'orders_status_valid';

-- Vérifier les politiques RLS
SELECT 'Politiques RLS créées:' as info;
SELECT 
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- Statistiques des commandes
SELECT 'Statistiques des commandes:' as info;
SELECT 
    COUNT(*) as total_orders,
    COUNT(CASE WHEN driver_id IS NOT NULL THEN 1 END) as assigned_orders,
    COUNT(CASE WHEN driver_id IS NULL THEN 1 END) as unassigned_orders,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_orders,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_orders,
    COUNT(CASE WHEN status = 'assigned' THEN 1 END) as assigned_status_orders,
    COUNT(CASE WHEN status = 'picked_up' THEN 1 END) as picked_up_orders,
    COUNT(CASE WHEN status = 'in_transit' THEN 1 END) as in_transit_orders,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_orders
FROM orders;

-- =====================================================
-- ÉTAPE 7: TEST DE LA CONTRAINTE
-- =====================================================

SELECT '🧪 ÉTAPE 7: Test de la contrainte' as info;

DO $$ 
BEGIN
    -- Test avec un statut valide
    BEGIN
        UPDATE orders SET status = 'assigned' WHERE id = (SELECT id FROM orders LIMIT 1);
        RAISE NOTICE '✅ Test avec statut valide réussi';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '❌ Test avec statut valide échoué';
    END;
    
    -- Test avec un statut invalide (devrait échouer)
    BEGIN
        UPDATE orders SET status = 'invalid_status' WHERE id = (SELECT id FROM orders LIMIT 1);
        RAISE NOTICE '❌ Test avec statut invalide a réussi (ne devrait pas)';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✅ Test avec statut invalide a échoué comme attendu';
    END;
END $$;

-- =====================================================
-- MESSAGE DE CONFIRMATION
-- =====================================================

SELECT '🎉 CORRECTION TERMINÉE AVEC SUCCÈS!' as message;
SELECT 'Le système de livreurs est maintenant opérationnel.' as info;
SELECT 'Les livreurs peuvent maintenant assigner et gérer les commandes.' as info;
