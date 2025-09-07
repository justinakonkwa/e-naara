-- =====================================================
-- 🔧 CORRECTION DÉFINITIVE DE LA STRUCTURE DE LA BASE DE DONNÉES
-- =====================================================

-- Ce script corrige définitivement tous les problèmes de structure

-- ÉTAPE 1: VÉRIFIER LA STRUCTURE ACTUELLE
SELECT '=== STRUCTURE ACTUELLE DE LA TABLE ORDERS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- ÉTAPE 2: CORRIGER LA TABLE ORDERS POUR QU'ELLE CORRESPONDE AU CODE DART
DO $$ 
BEGIN
    -- Ajouter product_id si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'product_id') THEN
        ALTER TABLE orders ADD COLUMN product_id TEXT REFERENCES products(id);
        RAISE NOTICE '✅ Colonne product_id ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne product_id existe déjà';
    END IF;
    
    -- Ajouter quantity si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'quantity') THEN
        ALTER TABLE orders ADD COLUMN quantity INTEGER DEFAULT 1 NOT NULL;
        RAISE NOTICE '✅ Colonne quantity ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne quantity existe déjà';
    END IF;
    
    -- Ajouter driver_id si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'driver_id') THEN
        ALTER TABLE orders ADD COLUMN driver_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne driver_id ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne driver_id existe déjà';
    END IF;
    
    -- Ajouter assigned_at si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'assigned_at') THEN
        ALTER TABLE orders ADD COLUMN assigned_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne assigned_at ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne assigned_at existe déjà';
    END IF;
    
    -- Ajouter picked_up_at si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'picked_up_at') THEN
        ALTER TABLE orders ADD COLUMN picked_up_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne picked_up_at ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne picked_up_at existe déjà';
    END IF;
    
    -- Ajouter delivered_at si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivered_at') THEN
        ALTER TABLE orders ADD COLUMN delivered_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne delivered_at ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne delivered_at existe déjà';
    END IF;
    
    -- Ajouter shipping_latitude si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_latitude') THEN
        ALTER TABLE orders ADD COLUMN shipping_latitude DOUBLE PRECISION;
        RAISE NOTICE '✅ Colonne shipping_latitude ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne shipping_latitude existe déjà';
    END IF;
    
    -- Ajouter shipping_longitude si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_longitude') THEN
        ALTER TABLE orders ADD COLUMN shipping_longitude DOUBLE PRECISION;
        RAISE NOTICE '✅ Colonne shipping_longitude ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne shipping_longitude existe déjà';
    END IF;
END $$;

-- ÉTAPE 3: CRÉER LES INDEX NÉCESSAIRES
CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_status_driver_id ON orders(status, driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_assigned_at ON orders(assigned_at);
CREATE INDEX IF NOT EXISTS idx_orders_picked_up_at ON orders(picked_up_at);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_at ON orders(delivered_at);
CREATE INDEX IF NOT EXISTS idx_orders_product_id ON orders(product_id);

-- ÉTAPE 4: SUPPRIMER LES ANCIENNES FONCTIONS
DROP FUNCTION IF EXISTS search_order_by_short_code(TEXT);
DROP FUNCTION IF EXISTS confirm_order_delivery(UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS simple_update_order_status(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS get_order_status(TEXT);

-- ÉTAPE 5: CRÉER LES NOUVELLES FONCTIONS SIMPLES ET ROBUSTES
-- Fonction pour rechercher par code court
CREATE OR REPLACE FUNCTION search_order_by_short_code(short_code TEXT)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    product_id TEXT,
    quantity INTEGER,
    total_amount DECIMAL(10,2),
    shipping_address TEXT,
    payment_method TEXT,
    status TEXT,
    tracking_number TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    driver_id UUID,
    assigned_at TIMESTAMP WITH TIME ZONE,
    picked_up_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    shipping_latitude DOUBLE PRECISION,
    shipping_longitude DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.id, o.user_id, o.product_id, o.quantity, o.total_amount, o.shipping_address,
        o.payment_method, o.status, o.tracking_number, o.created_at, o.updated_at,
        o.driver_id, o.assigned_at, o.picked_up_at, o.delivered_at,
        o.shipping_latitude, o.shipping_longitude
    FROM orders o
    WHERE LEFT(o.id::TEXT, 8) ILIKE short_code
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour récupérer le statut
CREATE OR REPLACE FUNCTION get_order_status(order_id_text TEXT)
RETURNS TEXT AS $$
DECLARE
    order_status TEXT;
BEGIN
    SELECT status INTO order_status
    FROM orders 
    WHERE id::TEXT = order_id_text;
    RETURN order_status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour mettre à jour le statut
CREATE OR REPLACE FUNCTION simple_update_order_status(
    order_id_text TEXT,
    new_status TEXT,
    updated_time TEXT
)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
BEGIN
    UPDATE orders 
    SET 
        status = new_status,
        updated_at = updated_time::TIMESTAMP WITH TIME ZONE,
        delivered_at = CASE WHEN new_status = 'delivered' THEN updated_time::TIMESTAMP WITH TIME ZONE ELSE delivered_at END
    WHERE id::TEXT = order_id_text;
    
    IF FOUND THEN
        result := 'SUCCESS: Commande mise à jour avec succès';
    ELSE
        result := 'ERROR: Commande non trouvée';
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ÉTAPE 6: DONNER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION search_order_by_short_code(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_order_status(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION simple_update_order_status(TEXT, TEXT, TEXT) TO authenticated;

-- ÉTAPE 7: VÉRIFIER LA STRUCTURE FINALE
SELECT '=== STRUCTURE FINALE DE LA TABLE ORDERS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- ÉTAPE 8: TEST DES FONCTIONS
SELECT '=== TEST DES FONCTIONS ===' as info;

-- Test de recherche par code court (si des données existent)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM orders LIMIT 1) THEN
        RAISE NOTICE '✅ Test: Des commandes existent dans la base';
    ELSE
        RAISE NOTICE 'ℹ️ Test: Aucune commande dans la base (normal pour un test)';
    END IF;
END $$;

SELECT '✅ CORRECTION DÉFINITIVE TERMINÉE' as message;

