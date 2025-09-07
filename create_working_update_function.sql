-- =====================================================
-- 🔧 FONCTION QUI FONCTIONNE AVEC LA STRUCTURE RÉELLE
-- =====================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS working_update_order_status(TEXT, TEXT);

-- Fonction qui fonctionne avec la structure réelle de la table
CREATE OR REPLACE FUNCTION working_update_order_status(
    order_uuid TEXT,
    new_status TEXT
)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
    order_exists BOOLEAN;
BEGIN
    -- Vérifier d'abord si la commande existe
    SELECT EXISTS(
        SELECT 1 FROM orders 
        WHERE id::TEXT = order_uuid
    ) INTO order_exists;
    
    IF NOT order_exists THEN
        RETURN 'ERROR: Commande non trouvée';
    END IF;
    
    -- Mettre à jour la commande en utilisant une approche différente
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
        result := 'ERROR: Échec de la mise à jour';
    END IF;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- En cas d'erreur, retourner le message d'erreur détaillé
        RETURN 'ERROR: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION working_update_order_status(TEXT, TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction working_update_order_status créée avec succès' as message;

-- Test avec l'UUID spécifique
SELECT working_update_order_status('211e4a65-64ed-4aae-92c0-64872c4316f1', 'delivered');

