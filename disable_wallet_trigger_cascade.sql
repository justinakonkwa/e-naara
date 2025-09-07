-- =====================================================
-- 🚫 DÉSACTIVATION COMPLÈTE DU TRIGGER add_money_to_user_wallet
-- =====================================================

-- 1. Lister tous les triggers sur la table orders
SELECT 
    'Triggers existants sur orders:' as message,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'orders';

-- 2. Supprimer la fonction avec CASCADE pour supprimer aussi les triggers
DROP FUNCTION IF EXISTS add_money_to_user_wallet() CASCADE;

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
    'test-order-456'::UUID,
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
WHERE id = 'test-order-456'::UUID;

-- 7. Nettoyer la commande de test
DELETE FROM orders WHERE id = 'test-order-456'::UUID;

-- 8. Test de mise à jour directe pour la confirmation de livraison
SELECT 'Test de mise a jour directe:' as test_message;

UPDATE orders 
SET 
    status = 'delivered',
    updated_at = NOW(),
    delivered_at = NOW()
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- 9. Vérifier le résultat de la mise à jour
SELECT 
    'Resultat de la mise a jour:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    delivered_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- 10. Message de succès
SELECT 'Trigger add_money_to_user_wallet desactive avec succes' as result;

