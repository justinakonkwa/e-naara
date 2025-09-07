-- =====================================================
-- 🔍 FONCTION POUR RÉCUPÉRER LE STATUT D'UNE COMMANDE
-- =====================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS get_order_status(TEXT);

-- Fonction pour récupérer le statut d'une commande
CREATE OR REPLACE FUNCTION get_order_status(order_id_text TEXT)
RETURNS TEXT AS $$
DECLARE
    order_status TEXT;
BEGIN
    -- Récupérer le statut de la commande
    SELECT status INTO order_status
    FROM orders 
    WHERE id::TEXT = order_id_text;
    
    -- Retourner le statut ou null si la commande n'existe pas
    RETURN order_status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION get_order_status(TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction get_order_status créée avec succès' as message;

