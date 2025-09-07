-- =====================================================
-- 🔍 DIAGNOSTIC ET SOLUTION FINALE
-- =====================================================

-- ÉTAPE 1: DIAGNOSTIC DE LA STRUCTURE RÉELLE
SELECT '=== DIAGNOSTIC DE LA STRUCTURE DE LA TABLE ORDERS ===' as info;

-- Vérifier toutes les colonnes de la table orders
SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Vérifier un exemple de données
SELECT '=== EXEMPLE DE DONNÉES ===' as info;

SELECT 
    id,
    pg_typeof(id) as id_type,
    id::TEXT as id_as_text,
    LEFT(id::TEXT, 8) as short_code,
    status
FROM orders 
LIMIT 1;

-- ÉTAPE 2: CRÉER UNE SOLUTION QUI FONCTIONNE AVEC LA STRUCTURE RÉELLE
SELECT '=== CRÉATION DE LA SOLUTION FINALE ===' as info;

-- Supprimer toutes les anciennes fonctions
DROP FUNCTION IF EXISTS final_working_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS execute_raw_sql(TEXT);
DROP FUNCTION IF EXISTS ultimate_bypass_delivery_confirmation(TEXT);
DROP FUNCTION IF EXISTS search_order_by_short_code(TEXT);
DROP FUNCTION IF EXISTS get_order_status(TEXT);
DROP FUNCTION IF EXISTS confirm_delivery_final(TEXT);

-- Fonction finale qui s'adapte à la structure réelle
CREATE OR REPLACE FUNCTION smart_delivery_confirmation(order_uuid TEXT)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
    order_count INTEGER;
    short_code TEXT;
    column_name TEXT;
    data_type TEXT;
BEGIN
    -- Extraire le code court
    short_code := LEFT(order_uuid, 8);
    
    -- Vérifier la structure de la table
    SELECT c.column_name, c.data_type INTO column_name, data_type
    FROM information_schema.columns c
    WHERE c.table_name = 'orders' 
        AND c.column_name = 'id'
    LIMIT 1;
    
    -- Si la colonne id n'existe pas, essayer d'autres colonnes
    IF column_name IS NULL THEN
        -- Chercher une colonne qui pourrait être l'identifiant
        SELECT c.column_name, c.data_type INTO column_name, data_type
        FROM information_schema.columns c
        WHERE c.table_name = 'orders' 
            AND (c.column_name LIKE '%id%' OR c.column_name LIKE '%uuid%')
        LIMIT 1;
    END IF;
    
    -- Si aucune colonne trouvée, retourner une erreur
    IF column_name IS NULL THEN
        RETURN 'ERROR: Aucune colonne d''identifiant trouvée dans la table orders';
    END IF;
    
    -- Essayer de mettre à jour avec la colonne trouvée
    BEGIN
        EXECUTE format('
            UPDATE orders 
            SET 
                status = %L,
                updated_at = NOW(),
                delivered_at = NOW()
            WHERE LEFT(%I::TEXT, 8) = %L
        ', 'delivered', column_name, short_code);
        
        GET DIAGNOSTICS order_count = ROW_COUNT;
        
        IF order_count > 0 THEN
            result := format('SUCCESS: Livraison confirmée avec succès (colonne: %s, type: %s)', column_name, data_type);
        ELSE
            result := format('ERROR: Commande non trouvée (colonne: %s, type: %s)', column_name, data_type);
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            result := format('ERROR: Échec avec la colonne %s - %s', column_name, SQLERRM);
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION smart_delivery_confirmation(TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction smart_delivery_confirmation créée avec succès' as message;

-- Test avec l'UUID spécifique
SELECT smart_delivery_confirmation('862d6aae-64ed-4aae-92c0-64872c4316f1');

