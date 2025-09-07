-- =====================================================
-- 🔍 DIAGNOSTIC DE LA CONFIRMATION DE LIVRAISON
-- =====================================================

-- 1. Vérifier si la fonction existe
SELECT 
    routine_name, 
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'confirm_delivery_by_uuid';

-- 2. Vérifier le statut actuel de la commande
SELECT 
    '📋 Statut actuel de la commande:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    driver_id,
    delivered_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '211e4a65';

-- 3. Tester la fonction de confirmation
SELECT '🔍 Test de la fonction confirm_delivery_by_uuid:' as test_message;
SELECT * FROM confirm_delivery_by_uuid(
    '211e4a65-64ed-4aae-92c0-64872c4316f1'::UUID,
    NOW()::TEXT,
    NOW()::TEXT
);

-- 4. Vérifier le statut après la confirmation
SELECT 
    '📋 Statut après confirmation:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    driver_id,
    delivered_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '211e4a65';

-- 5. Vérifier toutes les commandes avec le statut 'delivered'
SELECT 
    '📦 Commandes livrées:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    delivered_at,
    updated_at
FROM orders 
WHERE status = 'delivered'
ORDER BY delivered_at DESC
LIMIT 5;

-- 6. Vérifier les triggers sur la table orders
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'orders';

