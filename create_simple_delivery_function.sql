-- =====================================================
-- 🚚 FONCTION RPC SIMPLE POUR CONFIRMER LA LIVRAISON
-- =====================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS simple_confirm_delivery(UUID);

-- Fonction simple pour confirmer la livraison
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

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION simple_confirm_delivery(UUID) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction simple_confirm_delivery créée avec succès' as message;

-- Test avec l'UUID spécifique
SELECT '🔍 Test avec 211e4a65-64ed-4aae-92c0-64872c4316f1:' as test_message;
SELECT simple_confirm_delivery('211e4a65-64ed-4aae-92c0-64872c4316f1'::UUID) as result;

-- Vérifier le statut après le test
SELECT 
    '📋 Statut après test:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    delivered_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '211e4a65';
