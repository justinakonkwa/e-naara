-- =====================================================
-- 🧪 TEST SIMPLE DU SYSTÈME
-- =====================================================

-- Test 1: Vérifier la structure de la table products
SELECT 'Test 1: Structure de la table products' as test_name;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name IN ('quantity', 'is_available', 'updated_at', 'seller_id')
ORDER BY column_name;

-- Test 2: Vérifier la structure de la table orders
SELECT 'Test 2: Structure de la table orders' as test_name;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name IN ('product_id', 'quantity', 'total_amount', 'status', 'user_id', 'shipping_latitude', 'shipping_longitude')
ORDER BY column_name;

-- Test 3: Vérifier que les tables du portefeuille existent
SELECT 'Test 3: Tables du portefeuille' as test_name;

SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('wallets', 'wallet_transactions')
ORDER BY table_name;

-- Test 4: Vérifier les triggers principaux
SELECT 'Test 4: Triggers principaux' as test_name;

SELECT 
    trigger_name,
    event_object_table
FROM information_schema.triggers 
WHERE trigger_name IN (
    'update_product_quantity_trigger',
    'add_money_to_user_wallet_trigger',
    'create_wallet_for_user_trigger'
)
ORDER BY trigger_name;

-- Test 5: Statistiques des produits
SELECT 'Test 5: Statistiques des produits' as test_name;

SELECT 
    COUNT(*) as total_produits,
    COUNT(CASE WHEN is_available = true THEN 1 END) as produits_disponibles,
    COUNT(CASE WHEN quantity > 0 THEN 1 END) as produits_en_stock,
    AVG(quantity) as quantite_moyenne
FROM products;

-- Message de fin
SELECT '🎉 Tests terminés ! Vérifiez les résultats ci-dessus.' as message;
