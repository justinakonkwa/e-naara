-- =====================================================
-- 🚚 FONCTION RPC POUR CONFIRMER LA LIVRAISON
-- =====================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS confirm_delivery_by_uuid(UUID, TEXT, TEXT);

-- Fonction pour confirmer la livraison avec gestion explicite des types
CREATE OR REPLACE FUNCTION confirm_delivery_by_uuid(
    order_uuid UUID,
    delivered_at TEXT,
    updated_at TEXT
)
RETURNS JSON AS $$
DECLARE
    result JSON;
    affected_rows INTEGER;
BEGIN
    -- Mettre à jour la commande avec conversion explicite des types
    UPDATE orders 
    SET 
        status = 'delivered',
        updated_at = updated_at::TIMESTAMP WITH TIME ZONE,
        delivered_at = delivered_at::TIMESTAMP WITH TIME ZONE
    WHERE id = order_uuid;
    
    -- Vérifier combien de lignes ont été affectées
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    
    IF affected_rows > 0 THEN
        -- Récupérer la commande mise à jour
        SELECT json_build_object(
            'success', true,
            'message', 'Livraison confirmée avec succès',
            'order_id', o.id,
            'status', o.status,
            'delivered_at', o.delivered_at
        ) INTO result
        FROM orders o
        WHERE o.id = order_uuid;
        
        RETURN result;
    ELSE
        -- Aucune commande trouvée
        RETURN json_build_object(
            'success', false,
            'message', 'Aucune commande trouvée avec cet UUID',
            'order_uuid', order_uuid
        );
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Gestion d'erreur
        RETURN json_build_object(
            'success', false,
            'message', 'Erreur lors de la confirmation de livraison',
            'error', SQLERRM,
            'order_uuid', order_uuid
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION confirm_delivery_by_uuid(UUID, TEXT, TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction confirm_delivery_by_uuid créée avec succès' as message;

-- Test avec l'UUID spécifique
SELECT '🔍 Test avec 211e4a65-64ed-4aae-92c0-64872c4316f1:' as test_message;
SELECT * FROM confirm_delivery_by_uuid(
    '211e4a65-64ed-4aae-92c0-64872c4316f1'::UUID,
    NOW()::TEXT,
    NOW()::TEXT
);
