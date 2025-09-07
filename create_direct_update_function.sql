-- =====================================================
-- 🔧 FONCTION POUR METTRE À JOUR DIRECTEMENT LE STATUT D'UNE COMMANDE
-- =====================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS direct_update_order_status(TEXT, TEXT);

-- Fonction pour mettre à jour directement le statut d'une commande
CREATE OR REPLACE FUNCTION direct_update_order_status(
    order_uuid TEXT,
    new_status TEXT
)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
BEGIN
    -- Mettre à jour la commande avec le nouveau statut
    UPDATE orders 
    SET 
        status = new_status,
        updated_at = NOW(),
        delivered_at = CASE WHEN new_status = 'delivered' THEN NOW() ELSE delivered_at END
    WHERE id::TEXT = order_uuid;
    
    -- Vérifier si la mise à jour a été effectuée
    IF FOUND THEN
        result := 'SUCCESS: Commande mise à jour avec succès';
    ELSE
        result := 'ERROR: Commande non trouvée';
    END IF;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- En cas d'erreur, retourner le message d'erreur
        RETURN 'ERROR: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION direct_update_order_status(TEXT, TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction direct_update_order_status créée avec succès' as message;

-- Test avec l'UUID spécifique
SELECT direct_update_order_status('211e4a65-64ed-4aae-92c0-64872c4316f1', 'delivered');

