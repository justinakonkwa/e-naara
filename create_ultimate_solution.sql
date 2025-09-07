-- =====================================================
-- 🚀 SOLUTION ULTIME POUR CONFIRMER LA LIVRAISON
-- =====================================================

-- Supprimer toutes les anciennes fonctions
DROP FUNCTION IF EXISTS direct_update_order_status(TEXT, TEXT);
DROP FUNCTION IF EXISTS working_update_order_status(TEXT, TEXT);
DROP FUNCTION IF EXISTS simple_update_order_status(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS get_order_status(TEXT);
DROP FUNCTION IF EXISTS search_order_by_short_code(TEXT);

-- Fonction ultime qui fonctionne quelle que soit la structure
CREATE OR REPLACE FUNCTION ultimate_delivery_confirmation(order_uuid TEXT)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
    order_count INTEGER;
BEGIN
    -- Vérifier d'abord si la commande existe (peu importe le type de la colonne id)
    SELECT COUNT(*) INTO order_count
    FROM orders 
    WHERE id::TEXT = order_uuid;
    
    IF order_count = 0 THEN
        RETURN 'ERROR: Commande non trouvée';
    END IF;
    
    -- Mettre à jour la commande en utilisant une requête SQL brute
    EXECUTE format('
        UPDATE orders 
        SET 
            status = %L,
            updated_at = NOW(),
            delivered_at = NOW()
        WHERE id::TEXT = %L
    ', 'delivered', order_uuid);
    
    -- Vérifier si la mise à jour a été effectuée
    GET DIAGNOSTICS order_count = ROW_COUNT;
    
    IF order_count > 0 THEN
        result := 'SUCCESS: Livraison confirmée avec succès';
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
GRANT EXECUTE ON FUNCTION ultimate_delivery_confirmation(TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction ultimate_delivery_confirmation créée avec succès' as message;

-- Test avec l'UUID spécifique
SELECT ultimate_delivery_confirmation('211e4a65-64ed-4aae-92c0-64872c4316f1');

