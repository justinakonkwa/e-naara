-- =====================================================
-- 🔍 VÉRIFICATION DE LA STRUCTURE RÉELLE DE LA TABLE ORDERS
-- =====================================================

-- Vérifier le type exact de la colonne id
SELECT '=== TYPE DE LA COLONNE ID ===' as info;

SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
    AND column_name = 'id';

-- Vérifier toutes les colonnes de la table orders
SELECT '=== TOUTES LES COLONNES DE ORDERS ===' as info;

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

-- Vérifier les contraintes de la table
SELECT '=== CONTRAINTES DE LA TABLE ORDERS ===' as info;

SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'orders';

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

-- Test de comparaison directe
SELECT '=== TEST DE COMPARAISON DIRECTE ===' as info;

SELECT 
    CASE 
        WHEN id = '211e4a65-64ed-4aae-92c0-64872c4316f1'::UUID THEN 'UUID direct OK'
        WHEN id::TEXT = '211e4a65-64ed-4aae-92c0-64872c4316f1' THEN 'TEXT conversion OK'
        ELSE 'Aucune correspondance'
    END as test_result
FROM orders 
WHERE LEFT(id::TEXT, 8) = '211e4a65'
LIMIT 1;
