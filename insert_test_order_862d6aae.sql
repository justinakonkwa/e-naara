-- =====================================================
-- 🧪 INSERTION D'UNE COMMANDE DE TEST AVEC CODE COURT 862d6aae
-- =====================================================

-- Supprimer l'ancienne commande de test si elle existe
DELETE FROM orders WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- Insérer une nouvelle commande de test avec le code court 862d6aae
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
    '862d6aae-1234-5678-9abc-def012345678'::UUID,  -- Code court: 862d6aae
    '1e87d033-767a-46e5-9764-df8f5c2a08ea'::UUID,  -- User ID existant
    'test-product-123',
    1,
    29.99,
    '123 Test Street, Test City, 12345',
    'credit_card',
    'picked_up',  -- Statut pour test de livraison
    'TRACK123456',
    NOW(),
    NOW(),
    '1e87d033-767a-46e5-9764-df8f5c2a08ea'::UUID,  -- Driver ID
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '30 minutes',
    NULL,  -- Pas encore livrée
    37.4219983,
    -122.084
);

-- Vérifier que la commande a été insérée
SELECT 
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    driver_id,
    created_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- Tester la fonction de recherche
SELECT '✅ Test de la fonction search_by_short_code_simple:' as message;
SELECT * FROM search_by_short_code_simple('862d6aae');

-- Afficher le message de succès
SELECT '✅ Commande de test 862d6aae insérée avec succès !' as result;

