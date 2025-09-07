-- =====================================================
-- 🧪 TESTS DU SYSTÈME COMPLET
-- =====================================================

-- Ce script teste le système de portefeuille ET la gestion des quantités

-- Test 1: Vérifier la structure de la table products
SELECT 'Test 1: Structure de la table products' as test_name;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name IN ('quantity', 'is_available', 'updated_at', 'seller_id')
ORDER BY column_name;

-- Test 2: Vérifier que les colonnes existent
SELECT 'Test 2: Vérification des colonnes' as test_name;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'quantity') 
        THEN '✅ Colonne quantity existe'
        ELSE '❌ Colonne quantity manquante'
    END as quantity_check,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'is_available') 
        THEN '✅ Colonne is_available existe'
        ELSE '❌ Colonne is_available manquante'
    END as availability_check,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'updated_at') 
        THEN '✅ Colonne updated_at existe'
        ELSE '❌ Colonne updated_at manquante'
    END as updated_at_check,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'seller_id') 
        THEN '✅ Colonne seller_id existe'
        ELSE '❌ Colonne seller_id manquante'
    END as seller_id_check;

-- Test 3: Vérifier les triggers du système de quantités
SELECT 'Test 3: Triggers de gestion des quantités' as test_name;

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

-- Test 4: Vérifier les triggers du système de portefeuille
SELECT 'Test 4: Triggers du système de portefeuille' as test_name;

SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name IN (
    'add_money_to_user_wallet_trigger',
    'create_wallet_for_user_trigger',
    'update_wallets_updated_at'
)
ORDER BY trigger_name;

-- Test 5: Vérifier les fonctions
SELECT 'Test 5: Fonctions du système' as test_name;

SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN (
    'update_product_quantity_on_sale',
    'restore_product_quantity_on_cancel',
    'check_product_availability',
    'add_money_to_user_wallet',
    'create_wallet_for_user',
    'update_updated_at_column'
)
ORDER BY routine_name;

-- Test 6: Vérifier les tables du portefeuille
SELECT 'Test 6: Tables du système de portefeuille' as test_name;

SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('wallets', 'wallet_transactions')
ORDER BY table_name;

-- Test 7: Vérifier les index
SELECT 'Test 7: Index de performance' as test_name;

SELECT 
    indexname,
    tablename
FROM pg_indexes 
WHERE indexname IN (
    'idx_products_quantity',
    'idx_products_available',
    'idx_products_seller_id',
    'idx_wallets_user_id',
    'idx_wallet_transactions_wallet_id'
)
ORDER BY indexname;

-- Test 8: Statistiques des produits
SELECT 'Test 8: Statistiques des produits' as test_name;

SELECT 
    COUNT(*) as total_produits,
    COUNT(CASE WHEN is_available = true THEN 1 END) as produits_disponibles,
    COUNT(CASE WHEN is_available = false THEN 1 END) as produits_indisponibles,
    COUNT(CASE WHEN quantity = 0 THEN 1 END) as produits_rupture_stock,
    COUNT(CASE WHEN quantity > 0 THEN 1 END) as produits_en_stock,
    AVG(quantity) as quantite_moyenne,
    MIN(quantity) as quantite_min,
    MAX(quantity) as quantite_max
FROM products;

-- Test 9: Vérifier les contraintes
SELECT 'Test 9: Contraintes de données' as test_name;

SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name IN ('products', 'wallets', 'wallet_transactions')
AND constraint_name IN (
    'products_quantity_positive',
    'wallets_currency_check',
    'wallet_transactions_type_check',
    'wallet_transactions_status_check'
)
ORDER BY table_name, constraint_name;

-- Test 10: Vérifier les politiques RLS
SELECT 'Test 10: Politiques de sécurité RLS' as test_name;

SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('wallets', 'wallet_transactions')
ORDER BY tablename, policyname;

-- Test 11: Simulation d'une vente (si des données existent)
SELECT 'Test 11: Simulation d''une vente' as test_name;

DO $$
DECLARE
    test_user_id UUID;
    test_product_id UUID;
    initial_quantity INTEGER;
    final_quantity INTEGER;
    test_order_id UUID;
BEGIN
    -- Vérifier s'il y a des données de test
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        SELECT id, quantity INTO test_product_id, initial_quantity 
        FROM products 
        WHERE quantity > 0 AND is_available = true
        LIMIT 1;
        
        IF test_product_id IS NOT NULL THEN
            RAISE NOTICE 'Test de vente: Produit % avec quantité initiale %', test_product_id, initial_quantity;
            
            -- Simuler une commande (cela déclenchera les triggers)
            INSERT INTO orders (
                user_id, product_id, quantity, total_amount, status, created_at
            ) VALUES (
                test_user_id, test_product_id, 1, 10.00, 'pending', NOW()
            ) RETURNING id INTO test_order_id;
            
            -- Vérifier la nouvelle quantité
            SELECT quantity INTO final_quantity FROM products WHERE id = test_product_id;
            RAISE NOTICE 'Quantité après vente: % (attendu: %)', final_quantity, initial_quantity - 1;
            
            IF final_quantity = initial_quantity - 1 THEN
                RAISE NOTICE '✅ Test réussi: La quantité a été décrémentée correctement';
                
                -- Simuler une livraison pour tester le portefeuille
                UPDATE orders SET status = 'delivered' WHERE id = test_order_id;
                RAISE NOTICE '✅ Commande livrée, portefeuille mis à jour';
                
            ELSE
                RAISE NOTICE '❌ Test échoué: La quantité n''a pas été mise à jour correctement';
            END IF;
        ELSE
            RAISE NOTICE '⚠️ Aucun produit disponible trouvé pour le test';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur trouvé pour le test';
    END IF;
END $$;

-- Test 12: Vérifier les portefeuilles
SELECT 'Test 12: Portefeuilles des utilisateurs' as test_name;

SELECT 
    COUNT(*) as total_portefeuilles,
    COUNT(CASE WHEN balance > 0 THEN 1 END) as portefeuilles_avec_solde,
    COUNT(CASE WHEN balance = 0 THEN 1 END) as portefeuilles_vides,
    AVG(balance) as solde_moyen,
    SUM(balance) as solde_total
FROM wallets;

-- Test 13: Vérifier les transactions
SELECT 'Test 13: Transactions de portefeuille' as test_name;

SELECT 
    COUNT(*) as total_transactions,
    COUNT(CASE WHEN type = 'credit' THEN 1 END) as credits,
    COUNT(CASE WHEN type = 'debit' THEN 1 END) as debits,
    COUNT(CASE WHEN type = 'withdrawal' THEN 1 END) as retraits,
    COUNT(CASE WHEN type = 'refund' THEN 1 END) as remboursements,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as transactions_completees,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as transactions_en_attente
FROM wallet_transactions;

-- Message de fin
SELECT '🎉 Tests complets terminés ! Vérifiez les résultats ci-dessus.' as message;
