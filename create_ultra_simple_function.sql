-- =====================================================
-- 🚀 FONCTION ULTRA SIMPLE POUR CONFIRMER LA LIVRAISON
-- =====================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS ultra_simple_delivery_confirmation(TEXT);

-- Fonction ultra simple qui ne prend qu'un paramètre
CREATE OR REPLACE FUNCTION ultra_simple_delivery_confirmation(order_id_text TEXT)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
BEGIN
    -- Mettre à jour la commande avec le statut 'delivered' et la date actuelle
    UPDATE orders 
    SET 
        status = 'delivered',
        updated_at = NOW(),
        delivered_at = NOW()
    WHERE id::TEXT = order_id_text;
    
    -- Vérifier si la mise à jour a été effectuée
    IF FOUND THEN
        result := 'SUCCESS: Livraison confirmée avec succès';
    ELSE
        result := 'ERROR: Commande non trouvée';
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION ultra_simple_delivery_confirmation(TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction ultra_simple_delivery_confirmation créée avec succès' as message;

