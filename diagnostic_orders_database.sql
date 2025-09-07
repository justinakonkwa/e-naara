-- =====================================================
-- 🔍 DIAGNOSTIC COMPLET DE LA BASE DE DONNÉES
-- =====================================================

-- 1. Vérifier si la fonction existe
SELECT 
    routine_name, 
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'search_by_short_code_simple';

-- 2. Vérifier la structure de la table orders
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- 3. Compter le nombre total de commandes
SELECT COUNT(*) as total_orders FROM orders;

-- 4. Voir quelques exemples de commandes avec leurs IDs
SELECT 
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    created_at
FROM orders 
ORDER BY created_at DESC 
LIMIT 10;

-- 5. Rechercher spécifiquement le code court 862d6aae
SELECT 
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    created_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- 6. Tester la fonction avec le code court
SELECT * FROM search_by_short_code_simple('862d6aae');

-- 7. Voir tous les codes courts disponibles
SELECT DISTINCT 
    LEFT(id::TEXT, 8) as short_code,
    COUNT(*) as count
FROM orders 
GROUP BY LEFT(id::TEXT, 8)
ORDER BY count DESC;

-- 8. Vérifier s'il y a des commandes avec le statut 'picked_up'
SELECT 
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    driver_id
FROM orders 
WHERE status = 'picked_up'
ORDER BY updated_at DESC;

