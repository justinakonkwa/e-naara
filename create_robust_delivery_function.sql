-- =====================================================
-- 🚚 FONCTION RPC ROBUSTE POUR CONFIRMER LA LIVRAISON
-- =====================================================

-- 1. Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS robust_confirm_delivery(UUID);

-- 2. Créer une fonction plus robuste avec plus de logging
CREATE OR REPLACE FUNCTION robust_confirm_delivery(order_uuid UUID)
RETURNS JSON AS $$
DECLARE
    affected_rows INTEGER;
    order_status TEXT;
    order_exists BOOLEAN;
    result JSON;
BEGIN
    -- Vérifier si la commande existe
    SELECT EXISTS(SELECT 1 FROM orders WHERE id = order_uuid) INTO order_exists;
    
    IF NOT order_exists THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Commande non trouvée',
            'order_uuid', order_uuid
        );
    END IF;
    
    -- Récupérer le statut actuel
    SELECT status INTO order_status FROM orders WHERE id = order_uuid;
    
    -- Vérifier si la commande peut être livrée
    IF order_status = 'delivered' THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Commande déjà livrée',
            'current_status', order_status,
            'order_uuid', order_uuid
        );
    END IF;
    
    -- Mettre à jour la commande
    UPDATE orders 
    SET 
        status = 'delivered',
        updated_at = NOW(),
        delivered_at = NOW()
    WHERE id = order_uuid;
    
    -- Vérifier combien de lignes ont été affectées
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    
    IF affected_rows > 0 THEN
        -- Récupérer les données mises à jour
        SELECT json_build_object(
            'success', true,
            'message', 'Livraison confirmée avec succès',
            'order_uuid', o.id,
            'old_status', order_status,
            'new_status', o.status,
            'delivered_at', o.delivered_at,
            'affected_rows', affected_rows
        ) INTO result
        FROM orders o
        WHERE o.id = order_uuid;
        
        RETURN result;
    ELSE
        RETURN json_build_object(
            'success', false,
            'message', 'Aucune ligne mise à jour',
            'order_uuid', order_uuid,
            'current_status', order_status
        );
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Erreur lors de la confirmation',
            'error', SQLERRM,
            'order_uuid', order_uuid
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION robust_confirm_delivery(UUID) TO authenticated;

-- 4. Vérifier que la fonction a été créée
SELECT 
    '✅ Fonction robuste créée:' as message,
    routine_name, 
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'robust_confirm_delivery';

-- 5. Test de la fonction robuste
SELECT '🔍 Test de la fonction robuste:' as test_message;
SELECT * FROM robust_confirm_delivery('862d6aae-9bb1-4e48-802f-b5024040f031'::UUID);

-- 6. Vérifier le statut après le test
SELECT 
    '📋 Statut après test robuste:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    delivered_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- 7. Message de succès
SELECT '✅ Fonction robuste prête à utiliser' as result;

