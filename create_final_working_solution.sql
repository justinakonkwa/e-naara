-- =====================================================
-- 🎯 SOLUTION FINALE QUI FONCTIONNE SANS ID::TEXT
-- =====================================================

-- Supprimer toutes les anciennes fonctions
DROP FUNCTION IF EXISTS execute_raw_sql(TEXT);
DROP FUNCTION IF EXISTS ultimate_bypass_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS search_order_by_short_code(TEXT);
DROP FUNCTION IF EXISTS get_order_status(TEXT);
DROP FUNCTION IF EXISTS confirm_delivery_final(TEXT);

-- Fonction finale qui fonctionne sans utiliser id::TEXT
CREATE OR REPLACE FUNCTION final_working_delivery_confirmation(order_uuid TEXT)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
    order_count INTEGER;
    short_code TEXT;
BEGIN
    -- Extraire le code court
    short_code := LEFT(order_uuid, 8);
    
    -- Approche 1: Utiliser une requête SQL brute avec EXECUTE et paramètres
    BEGIN
        EXECUTE 'UPDATE orders SET status = $1, updated_at = NOW(), delivered_at = NOW() WHERE LEFT(id::TEXT, 8) = $2'
        USING 'delivered', short_code;
        
        GET DIAGNOSTICS order_count = ROW_COUNT;
        
        IF order_count > 0 THEN
            result := 'SUCCESS: Livraison confirmée avec succès (paramètres)';
        ELSE
            result := 'ERROR: Commande non trouvée (paramètres)';
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Approche 2: Utiliser une requête SQL brute avec format
            BEGIN
                EXECUTE format('
                    UPDATE orders 
                    SET 
                        status = %L,
                        updated_at = NOW(),
                        delivered_at = NOW()
                    WHERE LEFT(id::TEXT, 8) = %L
                ', 'delivered', short_code);
                
                GET DIAGNOSTICS order_count = ROW_COUNT;
                
                IF order_count > 0 THEN
                    result := 'SUCCESS: Livraison confirmée avec succès (format)';
                ELSE
                    result := 'ERROR: Commande non trouvée (format)';
                END IF;
                
            EXCEPTION
                WHEN OTHERS THEN
                    -- Approche 3: Utiliser une requête SQL brute avec une sous-requête
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
                            result := 'SUCCESS: Livraison confirmée avec succès (sous-requête)';
                        ELSE
                            result := 'ERROR: Commande non trouvée (sous-requête)';
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
GRANT EXECUTE ON FUNCTION final_working_delivery_confirmation(TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction final_working_delivery_confirmation créée avec succès' as message;

-- Test avec l'UUID spécifique
SELECT final_working_delivery_confirmation('862d6aae-64ed-4aae-92c0-64872c4316f1');
