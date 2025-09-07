-- =====================================================
-- 🔍 DIAGNOSTIC DU PROBLÈME DE CONFIRMATION DE LIVRAISON
-- =====================================================

-- 1. Vérifier si la commande existe avec cet UUID exact
SELECT 
    '🔍 Vérification de l existence de la commande:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    driver_id,
    delivered_at,
    updated_at,
    created_at
FROM orders 
WHERE id = '862d6aae-9bb1-4e48-802f-b5024040f031'::UUID;

-- 2. Vérifier toutes les commandes avec le code court 862d6aae
SELECT 
    '📋 Toutes les commandes avec le code court 862d6aae:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    driver_id,
    delivered_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae'
ORDER BY created_at DESC;

-- 3. Vérifier les contraintes sur la table orders
SELECT 
    '🔒 Contraintes sur la table orders:' as message,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'orders';

-- 4. Vérifier les triggers sur la table orders
SELECT 
    '⚡ Triggers sur la table orders:' as message,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'orders';

-- 5. Tester la fonction simple_confirm_delivery manuellement
SELECT '🔍 Test manuel de simple_confirm_delivery:' as test_message;

-- D'abord, vérifier le statut actuel
SELECT 
    '📋 Statut avant test:' as message,
    id,
    status,
    delivered_at
FROM orders 
WHERE id = '862d6aae-9bb1-4e48-802f-b5024040f031'::UUID;

-- Ensuite, tester la fonction
SELECT simple_confirm_delivery('862d6aae-9bb1-4e48-802f-b5024040f031'::UUID) as function_result;

-- Enfin, vérifier le statut après
SELECT 
    '📋 Statut après test:' as message,
    id,
    status,
    delivered_at
FROM orders 
WHERE id = '862d6aae-9bb1-4e48-802f-b5024040f031'::UUID;

-- 6. Vérifier s'il y a des commandes avec le statut 'delivered'
SELECT 
    '📦 Commandes déjà livrées:' as message,
    COUNT(*) as delivered_count
FROM orders 
WHERE status = 'delivered';

-- 7. Vérifier les permissions sur la table orders
SELECT 
    '🔐 Permissions sur orders:' as message,
    grantee,
    privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'orders'
AND grantee = 'authenticated';

-- 8. Test de mise à jour directe
SELECT '🔍 Test de mise à jour directe:' as test_message;

-- Mise à jour directe pour voir si ça fonctionne
UPDATE orders 
SET 
    status = 'delivered',
    updated_at = NOW(),
    delivered_at = NOW()
WHERE id = '862d6aae-9bb1-4e48-802f-b5024040f031'::UUID;

-- Vérifier le résultat
SELECT 
    '📋 Résultat de la mise à jour directe:' as message,
    id,
    status,
    delivered_at,
    updated_at
FROM orders 
WHERE id = '862d6aae-9bb1-4e48-802f-b5024040f031'::UUID;

-- 9. Message de diagnostic
SELECT '✅ Diagnostic terminé - vérifiez les résultats ci-dessus' as result;
