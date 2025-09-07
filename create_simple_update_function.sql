-- =====================================================
-- 🔧 FONCTION SIMPLE POUR METTRE À JOUR LE STATUT D'UNE COMMANDE
-- =====================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS simple_update_order_status(TEXT, TEXT, TEXT);

-- Fonction très simple pour mettre à jour le statut d'une commande
CREATE OR REPLACE FUNCTION simple_update_order_status(
    order_id_text TEXT,
    new_status TEXT,
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
        updated_at = updated_time::TIMESTAMP WITH TIME ZONE
    WHERE id::TEXT = order_id_text;
    
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
GRANT EXECUTE ON FUNCTION simple_update_order_status(TEXT, TEXT, TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction simple_update_order_status créée avec succès' as message;

