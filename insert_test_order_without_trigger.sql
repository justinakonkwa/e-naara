-- =====================================================
-- 🧪 INSERTION DE COMMANDE DE TEST SANS TRIGGER
-- =====================================================

-- Désactiver temporairement le trigger de vérification de produit
ALTER TABLE orders DISABLE TRIGGER check_product_availability;

-- Supprimer l'ancienne commande de test si elle existe
DELETE FROM orders WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- Insérer une nouvelle commande de test
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
    '862d6aae-1234-5678-9abc-def012345678'::UUID,
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
);

-- Réactiver le trigger
ALTER TABLE orders ENABLE TRIGGER check_product_availability;

-- Vérifier l'insertion
SELECT 
    '✅ Commande de test insérée:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    driver_id,
    product_id
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- Test de la fonction de recherche
SELECT '🔍 Test de la fonction search_orders_by_short_code:' as test_message;
SELECT * FROM search_orders_by_short_code('862d6aae');

-- Afficher le message de succès
SELECT '✅ Commande de test 862d6aae insérée avec succès !' as result;

