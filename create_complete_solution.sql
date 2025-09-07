-- =====================================================
-- 🔧 SOLUTION COMPLÈTE - RECRÉATION DE TOUTES LES FONCTIONS
-- =====================================================

-- Supprimer toutes les anciennes fonctions pour éviter les conflits
DROP FUNCTION IF EXISTS search_order_by_short_code(TEXT);
DROP FUNCTION IF EXISTS get_order_status(TEXT);
DROP FUNCTION IF EXISTS execute_sql(TEXT);
DROP FUNCTION IF EXISTS final_working_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS smart_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS bypass_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS final_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS ultimate_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS direct_update_order_status(TEXT, TEXT);
DROP FUNCTION IF EXISTS working_update_order_status(TEXT, TEXT);
DROP FUNCTION IF EXISTS simple_update_order_status(TEXT, TEXT, TEXT);

-- 1. Fonction pour rechercher par code court
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

-- 2. Fonction pour récupérer le statut
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

-- 3. Fonction pour confirmer la livraison
CREATE OR REPLACE FUNCTION confirm_delivery_final(order_uuid TEXT)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
    order_count INTEGER;
    short_code TEXT;
BEGIN
    -- Extraire le code court
    short_code := LEFT(order_uuid, 8);
    
    -- Utiliser une requête SQL brute avec EXECUTE
    BEGIN
        EXECUTE 'UPDATE orders SET status = $1, updated_at = NOW(), delivered_at = NOW() WHERE LEFT(id::TEXT, 8) = $2'
        USING 'delivered', short_code;
        
        GET DIAGNOSTICS order_count = ROW_COUNT;
        
        IF order_count > 0 THEN
            result := 'SUCCESS: Livraison confirmée avec succès';
        ELSE
            result := 'ERROR: Commande non trouvée';
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            result := 'ERROR: ' || SQLERRM;
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION search_order_by_short_code(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_order_status(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION confirm_delivery_final(TEXT) TO authenticated;

-- Test des fonctions
SELECT '✅ Toutes les fonctions créées avec succès' as message;

-- Test de la fonction de recherche
SELECT * FROM search_order_by_short_code('862d6aae');

-- Test de la fonction de confirmation
SELECT confirm_delivery_final('862d6aae-64ed-4aae-92c0-64872c4316f1');

