-- =====================================================
-- 🧪 TESTS DU SYSTÈME DE GESTION DES QUANTITÉS
-- =====================================================

-- Ce script teste le système de gestion automatique des quantités

-- Test 1: Vérifier que les triggers existent
SELECT 'Test 1: Vérification des triggers' as test_name;

SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name IN (
    'update_product_quantity_trigger',
    'restore_product_quantity_trigger',
    'check_product_availability_trigger'
)
ORDER BY trigger_name;

-- Test 2: Vérifier que les fonctions existent
SELECT 'Test 2: Vérification des fonctions' as test_name;

SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN (
    'update_product_quantity_on_sale',
    'restore_product_quantity_on_cancel',
    'check_product_availability'
)
ORDER BY routine_name;

-- Test 3: Vérifier la structure de la table products
SELECT 'Test 3: Vérification de la structure de la table products' as test_name;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name IN ('quantity', 'is_available', 'updated_at')
ORDER BY column_name;

-- Test 4: Vérifier les index
SELECT 'Test 4: Vérification des index' as test_name;

SELECT 
    indexname,
    tablename,
    indexdef
FROM pg_indexes 
WHERE tablename = 'products' 
AND indexname IN ('idx_products_quantity', 'idx_products_available');

-- Test 5: Simuler une vente (nécessite des données de test)
SELECT 'Test 5: Simulation d''une vente' as test_name;

-- Note: Ce test nécessite des données de test dans les tables users, products, et orders
-- Il sera exécuté seulement si des données existent

DO $$
DECLARE
    test_user_id UUID;
    test_product_id UUID;
    initial_quantity INTEGER;
    final_quantity INTEGER;
BEGIN
    -- Vérifier s'il y a des données de test
    SELECT id INTO test_user_id FROM users LIMIT 1;
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        SELECT id, quantity INTO test_product_id, initial_quantity 
        FROM products 
        WHERE quantity > 0 
        LIMIT 1;
        
        IF test_product_id IS NOT NULL THEN
            RAISE NOTICE 'Test de vente: Produit % avec quantité initiale %', test_product_id, initial_quantity;
            
            -- Simuler une commande (cela déclenchera les triggers)
            INSERT INTO orders (
                user_id, product_id, quantity, total_amount, status, created_at
            ) VALUES (
                test_user_id, test_product_id, 1, 10.00, 'pending', NOW()
            );
            
            -- Vérifier la nouvelle quantité
            SELECT quantity INTO final_quantity FROM products WHERE id = test_product_id;
            RAISE NOTICE 'Quantité après vente: % (attendu: %)', final_quantity, initial_quantity - 1;
            
            IF final_quantity = initial_quantity - 1 THEN
                RAISE NOTICE '✅ Test réussi: La quantité a été décrémentée correctement';
            ELSE
                RAISE NOTICE '❌ Test échoué: La quantité n''a pas été mise à jour correctement';
            END IF;
        ELSE
            RAISE NOTICE '⚠️ Aucun produit avec quantité > 0 trouvé pour le test';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur trouvé pour le test';
    END IF;
END $$;

-- Test 6: Vérifier les contraintes de disponibilité
SELECT 'Test 6: Vérification des contraintes' as test_name;

-- Vérifier que les produits avec quantité 0 sont marqués comme indisponibles
SELECT 
    COUNT(*) as produits_indisponibles,
    COUNT(CASE WHEN quantity = 0 AND is_available = false THEN 1 END) as correctement_marques
FROM products 
WHERE quantity = 0;

-- Test 7: Statistiques des produits
SELECT 'Test 7: Statistiques des produits' as test_name;

SELECT 
    COUNT(*) as total_produits,
    COUNT(CASE WHEN is_available = true THEN 1 END) as produits_disponibles,
    COUNT(CASE WHEN is_available = false THEN 1 END) as produits_indisponibles,
    COUNT(CASE WHEN quantity = 0 THEN 1 END) as produits_rupture_stock,
    AVG(quantity) as quantite_moyenne
FROM products;

-- Test 8: Vérifier les triggers de portefeuille
SELECT 'Test 8: Vérification des triggers de portefeuille' as test_name;

SELECT 
    trigger_name,
    event_object_table
FROM information_schema.triggers 
WHERE trigger_name IN (
    'add_money_to_user_wallet_trigger',
    'create_wallet_for_user_trigger'
);

-- Message de fin
SELECT '🎉 Tests terminés ! Vérifiez les résultats ci-dessus.' as message;
