-- =====================================================
-- 🧪 TEST SIMPLE DU SYSTÈME DE CODES COURTS
-- =====================================================

-- Test 1: Voir les commandes existantes avec leurs codes courts
SELECT '📋 Test 1: Commandes existantes' as info;

SELECT 
    id as uuid_complet,
    LEFT(id::TEXT, 8) as code_court,
    status,
    created_at
FROM orders 
ORDER BY created_at DESC 
LIMIT 5;

-- Test 2: Rechercher une commande par code court
SELECT '🔍 Test 2: Recherche par code court' as info;

-- Prendre le code court de la première commande et tester la recherche
WITH first_order AS (
    SELECT id, LEFT(id::TEXT, 8) as short_code
    FROM orders 
    LIMIT 1
)
SELECT 
    'Code court testé: ' || short_code as test_info,
    'UUID trouvé: ' || id as result
FROM first_order;

-- Test 3: Tester la recherche avec ILIKE
SELECT '🔍 Test 3: Recherche avec ILIKE' as info;

-- Rechercher toutes les commandes qui commencent par un code court spécifique
-- (remplacez '15F403E3' par un code court réel de votre base)
SELECT 
    id,
    LEFT(id::TEXT, 8) as code_court,
    status
FROM orders 
WHERE LEFT(id::TEXT, 8) ILIKE '15F403E3'
LIMIT 5;

-- Test 4: Vérifier le format des UUID
SELECT '📊 Test 4: Format des UUID' as info;

SELECT 
    'Longueur UUID: ' || LENGTH(id::TEXT) as uuid_length,
    'Format UUID: ' || 
        CASE 
            WHEN id::TEXT ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
            THEN '✅ Format UUID valide'
            ELSE '❌ Format UUID invalide'
        END as uuid_format
FROM orders 
LIMIT 1;

-- Test 5: Statistiques
SELECT '📈 Test 5: Statistiques' as info;

SELECT 
    COUNT(*) as total_commandes,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as en_attente,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmees,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as livrees
FROM orders;

-- Message de fin
SELECT '✅ Test terminé !' as message;
