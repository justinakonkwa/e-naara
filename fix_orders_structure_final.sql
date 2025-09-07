-- =====================================================
-- 🔧 CORRECTION DÉFINITIVE DE LA TABLE ORDERS
-- =====================================================

-- Étape 1: Vérifier la structure actuelle
SELECT 'Structure actuelle de la table orders:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Étape 2: Ajouter les colonnes manquantes pour la gestion des livreurs
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

-- Étape 3: Créer les index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_status_driver_id ON orders(status, driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_assigned_at ON orders(assigned_at);
CREATE INDEX IF NOT EXISTS idx_orders_picked_up_at ON orders(picked_up_at);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_at ON orders(delivered_at);

-- Étape 4: Vérifier la structure finale
SELECT 'Structure finale de la table orders:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Étape 5: Créer une fonction simple pour confirmer la livraison
DROP FUNCTION IF EXISTS update_order_delivery_status(TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION update_order_delivery_status(
    order_id TEXT,
    new_status TEXT,
    delivered_time TEXT,
    updated_time TEXT
)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
BEGIN
    -- Mettre à jour la commande en convertissant l'ID en UUID
    UPDATE orders 
    SET 
        status = new_status,
        delivered_at = delivered_time::TIMESTAMP WITH TIME ZONE,
        updated_at = updated_time::TIMESTAMP WITH TIME ZONE
    WHERE id::TEXT = order_id;
    
    -- Vérifier si la mise à jour a été effectuée
    IF FOUND THEN
        result := 'SUCCESS: Commande mise à jour avec succès';
    ELSE
        result := 'ERROR: Commande non trouvée';
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION update_order_delivery_status(TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- Étape 6: Test de la fonction
SELECT 'Test de la fonction update_order_delivery_status:' as info;

-- Message de succès
SELECT '🎉 Structure de la table orders corrigée avec succès !' as message;

