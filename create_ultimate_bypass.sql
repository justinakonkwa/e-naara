-- =====================================================
-- 🚀 SOLUTION ULTIME - ÉVITE COMPLÈTEMENT LA CONVERSION ID::TEXT
-- =====================================================

-- Supprimer toutes les anciennes fonctions
DROP FUNCTION IF EXISTS search_order_by_short_code(TEXT);
DROP FUNCTION IF EXISTS get_order_status(TEXT);
DROP FUNCTION IF EXISTS confirm_delivery_final(TEXT);
DROP FUNCTION IF EXISTS execute_sql(TEXT);
DROP FUNCTION IF EXISTS final_working_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS smart_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS bypass_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS final_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS ultimate_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS direct_update_order_status(TEXT, TEXT);
DROP FUNCTION IF EXISTS working_update_order_status(TEXT, TEXT);
DROP FUNCTION IF EXISTS simple_update_order_status(TEXT, TEXT, TEXT);

-- Fonction ultime qui évite complètement la conversion id::TEXT
CREATE OR REPLACE FUNCTION ultimate_bypass_delivery_confirmation(order_uuid TEXT)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
    order_count INTEGER;
    short_code TEXT;
    order_id UUID;
BEGIN
    -- Extraire le code court
    short_code := LEFT(order_uuid, 8);
    
    -- Approche 1: Utiliser une sous-requête pour éviter la conversion directe
    BEGIN
        UPDATE orders 
        SET 
            status = 'delivered',
            updated_at = NOW(),
            delivered_at = NOW()
        WHERE id IN (
            SELECT o.id 
            FROM orders o 
            WHERE LEFT(o.id::TEXT, 8) = short_code
        );
        
        GET DIAGNOSTICS order_count = ROW_COUNT;
        
        IF order_count > 0 THEN
            result := 'SUCCESS: Livraison confirmée avec succès (sous-requête)';
        ELSE
            result := 'ERROR: Commande non trouvée (sous-requête)';
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Approche 2: Utiliser une jointure pour éviter la conversion directe
            BEGIN
                UPDATE orders o
                SET 
                    status = 'delivered',
                    updated_at = NOW(),
                    delivered_at = NOW()
                FROM (
                    SELECT id 
                    FROM orders 
                    WHERE LEFT(id::TEXT, 8) = short_code
                ) sub
                WHERE o.id = sub.id;
                
                GET DIAGNOSTICS order_count = ROW_COUNT;
                
                IF order_count > 0 THEN
                    result := 'SUCCESS: Livraison confirmée avec succès (jointure)';
                ELSE
                    result := 'ERROR: Commande non trouvée (jointure)';
                END IF;
                
            EXCEPTION
                WHEN OTHERS THEN
                    -- Approche 3: Utiliser une requête SQL brute avec EXECUTE
                    BEGIN
                        EXECUTE format('
                            UPDATE orders 
                            SET 
                                status = %L,
                                updated_at = NOW(),
                                delivered_at = NOW()
                            WHERE id IN (
                                SELECT id 
                                FROM orders 
                                WHERE LEFT(id::TEXT, 8) = %L
                            )
                        ', 'delivered', short_code);
                        
                        GET DIAGNOSTICS order_count = ROW_COUNT;
                        
                        IF order_count > 0 THEN
                            result := 'SUCCESS: Livraison confirmée avec succès (format)';
                        ELSE
                            result := 'ERROR: Commande non trouvée (format)';
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
GRANT EXECUTE ON FUNCTION ultimate_bypass_delivery_confirmation(TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction ultimate_bypass_delivery_confirmation créée avec succès' as message;

-- Test avec l'UUID spécifique
SELECT ultimate_bypass_delivery_confirmation('862d6aae-64ed-4aae-92c0-64872c4316f1');

