-- =====================================================
-- 🚚 CORRECTION DIRECTE DE LA CONFIRMATION DE LIVRAISON
-- =====================================================

-- 1. Vérifier le statut actuel
SELECT 
    '📋 Statut actuel de la commande:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    driver_id,
    delivered_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '211e4a65';

-- 2. Mettre à jour directement la commande
UPDATE orders 
SET 
    status = 'delivered',
    updated_at = NOW(),
    delivered_at = NOW()
WHERE LEFT(id::TEXT, 8) = '211e4a65';

-- 3. Vérifier le nombre de lignes affectées
SELECT 
    '✅ Lignes mises à jour:' as message,
    COUNT(*) as affected_rows
FROM orders 
WHERE LEFT(id::TEXT, 8) = '211e4a65' AND status = 'delivered';

-- 4. Vérifier le nouveau statut
SELECT 
    '📋 Nouveau statut de la commande:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    driver_id,
    delivered_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '211e4a65';

-- 5. Créer une fonction RPC simple qui fonctionne
DROP FUNCTION IF EXISTS direct_confirm_delivery(TEXT);

CREATE OR REPLACE FUNCTION direct_confirm_delivery(short_code TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    -- Mettre à jour la commande en utilisant le code court
    UPDATE orders 
    SET 
        status = 'delivered',
        updated_at = NOW(),
        delivered_at = NOW()
    WHERE LEFT(id::TEXT, 8) = short_code;
    
    -- Vérifier combien de lignes ont été affectées
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    
    -- Retourner true si au moins une ligne a été mise à jour
    RETURN affected_rows > 0;
    
EXCEPTION
    WHEN OTHERS THEN
        -- En cas d'erreur, retourner false
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION direct_confirm_delivery(TEXT) TO authenticated;

-- 6. Tester la nouvelle fonction
SELECT '✅ Fonction direct_confirm_delivery créée avec succès' as message;

-- 7. Test de la fonction avec le code court
SELECT '🔍 Test de la fonction direct_confirm_delivery:' as test_message;
SELECT direct_confirm_delivery('211e4a65') as result;

-- 8. Vérifier le statut final
SELECT 
    '📋 Statut final après test:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    delivered_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '211e4a65';

