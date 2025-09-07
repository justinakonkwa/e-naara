-- =====================================================
-- 🔍 FONCTION SIMPLE POUR RECHERCHER PAR CODE COURT
-- =====================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS search_by_short_code_simple(TEXT);

-- Fonction simple pour rechercher par code court
CREATE OR REPLACE FUNCTION search_by_short_code_simple(short_code TEXT)
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
    WHERE LEFT(o.id::TEXT, 8) = short_code
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION search_by_short_code_simple(TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction search_by_short_code_simple créée avec succès' as message;

-- Test avec le code court spécifique
SELECT * FROM search_by_short_code_simple('862d6aae');

