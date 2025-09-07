-- =====================================================
-- 🚫 DÉSACTIVATION DU TRIGGER add_money_to_user_wallet
-- =====================================================

-- 1. Désactiver le trigger
DROP TRIGGER IF EXISTS add_money_to_user_wallet ON orders;

-- 2. Supprimer la fonction
DROP FUNCTION IF EXISTS add_money_to_user_wallet();

-- 3. Vérifier qu'il n'y a plus de triggers sur orders
SELECT 
    'Triggers restants sur orders:' as message,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_table = 'orders';

-- 4. Vérifier qu'il n'y a plus de fonctions liées
SELECT 
    'Fonctions restantes:' as message,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name LIKE '%wallet%'
OR routine_name LIKE '%money%';

-- 5. Test d'insertion d'une commande sans trigger
SELECT 'Test d insertion sans trigger:' as test_message;

-- Insérer une commande de test pour vérifier qu'il n'y a pas d'erreur
INSERT INTO orders (
    id,
    user_id,
    product_id,
    quantity,
    total_amount,
    shipping_address,
    payment_method,
    status,
    tracking_number,
    created_at,
    updated_at,
    driver_id,
    assigned_at,
    picked_up_at,
    delivered_at,
    shipping_latitude,
    shipping_longitude
) VALUES (
    'test-order-123'::UUID,
    '1e87d033-767a-46e5-9764-df8f5c2a08ea'::UUID,
    'test-product-123',
    1,
    29.99,
    '123 Test Street, Test City, 12345',
    'credit_card',
    'picked_up',
    'TRACK123456',
    NOW(),
    NOW(),
    '1e87d033-767a-46e5-9764-df8f5c2a08ea'::UUID,
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '30 minutes',
    NULL,
    37.4219983,
    -122.084
) ON CONFLICT (id) DO NOTHING;

-- 6. Vérifier que l'insertion a réussi
SELECT 
    'Verification de l insertion:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    product_id
FROM orders 
WHERE id = 'test-order-123'::UUID;

-- 7. Nettoyer la commande de test
DELETE FROM orders WHERE id = 'test-order-123'::UUID;

-- 8. Message de succès
SELECT 'Trigger add_money_to_user_wallet desactive avec succes' as result;

