-- =====================================================
-- 🎯 SOLUTION FINALE SANS PROBLÈME DE TYPE UUID
-- =====================================================

-- Supprimer toutes les anciennes fonctions
DROP FUNCTION IF EXISTS ultimate_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS direct_update_order_status(TEXT, TEXT);
DROP FUNCTION IF EXISTS working_update_order_status(TEXT, TEXT);
DROP FUNCTION IF EXISTS simple_update_order_status(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS get_order_status(TEXT);
DROP FUNCTION IF EXISTS search_order_by_short_code(TEXT);

-- Fonction finale qui utilise une approche complètement différente
CREATE OR REPLACE FUNCTION final_delivery_confirmation(order_uuid TEXT)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
    order_count INTEGER;
BEGIN
    -- Approche 1: Utiliser une requête SQL brute avec CAST explicite
    BEGIN
        UPDATE orders 
        SET 
            status = 'delivered',
            updated_at = NOW(),
            delivered_at = NOW()
        WHERE CAST(id AS TEXT) = order_uuid;
        
        GET DIAGNOSTICS order_count = ROW_COUNT;
        
        IF order_count > 0 THEN
            result := 'SUCCESS: Livraison confirmée avec succès';
        ELSE
            result := 'ERROR: Commande non trouvée';
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Si l'approche 1 échoue, essayer l'approche 2
            BEGIN
                UPDATE orders 
                SET 
                    status = 'delivered',
                    updated_at = NOW(),
                    delivered_at = NOW()
                WHERE id = order_uuid::UUID;
                
                GET DIAGNOSTICS order_count = ROW_COUNT;
                
                IF order_count > 0 THEN
                    result := 'SUCCESS: Livraison confirmée avec succès (approche 2)';
                ELSE
                    result := 'ERROR: Commande non trouvée (approche 2)';
                END IF;
                
            EXCEPTION
                WHEN OTHERS THEN
                    -- Si les deux approches échouent, essayer l'approche 3
                    BEGIN
                        UPDATE orders 
                        SET 
                            status = 'delivered',
                            updated_at = NOW(),
                            delivered_at = NOW()
                        WHERE id::TEXT LIKE order_uuid || '%';
                        
                        GET DIAGNOSTICS order_count = ROW_COUNT;
                        
                        IF order_count > 0 THEN
                            result := 'SUCCESS: Livraison confirmée avec succès (approche 3)';
                        ELSE
                            result := 'ERROR: Commande non trouvée (approche 3)';
                        END IF;
                        
                    EXCEPTION
                        WHEN OTHERS THEN
                            result := 'ERROR: Toutes les approches ont échoué - ' || SQLERRM;
                    END;
            END;
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION final_delivery_confirmation(TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction final_delivery_confirmation créée avec succès' as message;

-- Test avec l'UUID spécifique
SELECT final_delivery_confirmation('211e4a65-64ed-4aae-92c0-64872c4316f1');

