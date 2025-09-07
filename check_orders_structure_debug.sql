-- =====================================================
-- 🔍 DIAGNOSTIC DE LA STRUCTURE DE LA TABLE ORDERS
-- =====================================================

-- Vérifier la structure de la table orders
SELECT '=== STRUCTURE DE LA TABLE ORDERS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Vérifier les contraintes de clés primaires
SELECT '=== CONTRAINTES DE CLÉS PRIMAIRES ===' as info;

SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'orders' 
    AND tc.constraint_type = 'PRIMARY KEY';

-- Vérifier les données existantes
SELECT '=== DONNÉES EXISTANTES ===' as info;

SELECT 
    COUNT(*) as total_commandes,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as en_attente,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmees,
    COUNT(CASE WHEN status = 'picked_up' THEN 1 END) as recuperees,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as livrees
FROM orders;

-- Vérifier un exemple de commande avec l'ID spécifique
SELECT '=== EXEMPLE DE COMMANDE AVEC ID SPÉCIFIQUE ===' as info;

SELECT 
    id,
    id::TEXT as id_as_text,
    LEFT(id::TEXT, 8) as short_code,
    user_id,
    status,
    created_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '211e4a65'
LIMIT 1;

-- Test de la fonction de recherche par code court
SELECT '=== TEST DE LA FONCTION SEARCH_ORDER_BY_SHORT_CODE ===' as info;

SELECT * FROM search_order_by_short_code('211e4a65');

-- Test de la fonction get_order_status
SELECT '=== TEST DE LA FONCTION GET_ORDER_STATUS ===' as info;

SELECT get_order_status('211e4a65-64ed-4aae-92c0-64872c4316f1');

