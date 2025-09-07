-- =====================================================
-- 🚚 ASSURANCE QUE LA FONCTION simple_confirm_delivery EXISTE
-- =====================================================

-- 1. Vérifier si la fonction existe
SELECT 
    '🔍 Vérification de la fonction:' as message,
    routine_name, 
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'simple_confirm_delivery';

-- 2. Recréer la fonction si elle n'existe pas ou la corriger
DROP FUNCTION IF EXISTS simple_confirm_delivery(UUID);

CREATE OR REPLACE FUNCTION simple_confirm_delivery(order_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    -- Mettre à jour la commande
    UPDATE orders 
    SET 
        status = 'delivered',
        updated_at = NOW(),
        delivered_at = NOW()
    WHERE id = order_uuid;
    
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

-- 3. Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION simple_confirm_delivery(UUID) TO authenticated;

-- 4. Vérifier que la fonction a été créée
SELECT 
    '✅ Fonction créée:' as message,
    routine_name, 
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'simple_confirm_delivery';

-- 5. Vérifier le statut actuel de la commande
SELECT 
    '📋 Statut actuel de la commande:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    driver_id,
    delivered_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- 6. Tester la fonction avec l'UUID spécifique
SELECT '🔍 Test de la fonction simple_confirm_delivery:' as test_message;
SELECT simple_confirm_delivery('862d6aae-9bb1-4e48-802f-b5024040f031'::UUID) as result;

-- 7. Vérifier le statut après le test
SELECT 
    '📋 Statut après test:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    delivered_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- 8. Vérifier toutes les fonctions RPC disponibles
SELECT 
    '📋 Fonctions RPC disponibles:' as message,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- 9. Message de succès
SELECT '✅ Fonction simple_confirm_delivery prête à utiliser' as result;

