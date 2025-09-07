-- =====================================================
-- 🧪 SCRIPT DE TEST DU SYSTÈME DE PORTEFEUILLE
-- =====================================================

-- Test 1: Vérifier que les tables existent
SELECT 'Test 1: Vérification des tables' as test_name;

SELECT 
    table_name,
    CASE 
        WHEN table_name = 'wallets' THEN '✅ Table wallets existe'
        WHEN table_name = 'wallet_transactions' THEN '✅ Table wallet_transactions existe'
        ELSE '❌ Table manquante'
    END as status
FROM information_schema.tables 
WHERE table_name IN ('wallets', 'wallet_transactions')
AND table_schema = 'public';

-- Test 2: Vérifier la structure de la table wallets
SELECT 'Test 2: Structure de la table wallets' as test_name;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'currency' AND column_default = '''USD''::character varying' THEN '✅ Devise par défaut USD'
        WHEN column_name = 'currency' THEN '⚠️ Devise par défaut incorrecte'
        ELSE '✅ OK'
    END as status
FROM information_schema.columns 
WHERE table_name = 'wallets'
ORDER BY ordinal_position;

-- Test 3: Vérifier les contraintes sur la devise
SELECT 'Test 3: Contraintes sur la devise' as test_name;

SELECT 
    constraint_name,
    constraint_type,
    CASE 
        WHEN constraint_type = 'CHECK' THEN '✅ Contrainte CHECK présente'
        ELSE '⚠️ Contrainte manquante'
    END as status
FROM information_schema.table_constraints 
WHERE table_name = 'wallets' 
AND constraint_type = 'CHECK';

-- Test 4: Vérifier les politiques RLS
SELECT 'Test 4: Politiques RLS' as test_name;

SELECT 
    policyname,
    permissive,
    cmd,
    CASE 
        WHEN cmd = 'SELECT' THEN '✅ Politique SELECT'
        WHEN cmd = 'INSERT' THEN '✅ Politique INSERT'
        WHEN cmd = 'UPDATE' THEN '✅ Politique UPDATE'
        ELSE '⚠️ Politique inconnue'
    END as status
FROM pg_policies 
WHERE tablename = 'wallets'
ORDER BY policyname;

-- Test 5: Vérifier les triggers
SELECT 'Test 5: Triggers' as test_name;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    CASE 
        WHEN trigger_name = 'create_wallet_for_user_trigger' THEN '✅ Trigger de création automatique'
        WHEN trigger_name = 'update_wallets_updated_at' THEN '✅ Trigger de mise à jour'
        ELSE '⚠️ Trigger inconnu'
    END as status
FROM information_schema.triggers 
WHERE event_object_table = 'wallets'
ORDER BY trigger_name;

-- Test 6: Vérifier les index
SELECT 'Test 6: Index' as test_name;

SELECT 
    indexname,
    indexdef,
    CASE 
        WHEN indexname LIKE '%user_id%' THEN '✅ Index sur user_id'
        WHEN indexname LIKE '%wallet_id%' THEN '✅ Index sur wallet_id'
        WHEN indexname LIKE '%created_at%' THEN '✅ Index sur created_at'
        ELSE '⚠️ Index inconnu'
    END as status
FROM pg_indexes 
WHERE tablename IN ('wallets', 'wallet_transactions')
ORDER BY indexname;

-- Test 7: Vérifier la colonne seller_id dans products
SELECT 'Test 7: Colonne seller_id dans products' as test_name;

SELECT 
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name = 'seller_id' THEN '✅ Colonne seller_id présente'
        ELSE '❌ Colonne seller_id manquante'
    END as status
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name = 'seller_id';

-- Test 8: Vérifier les rôles utilisateur
SELECT 'Test 8: Rôles utilisateur' as test_name;

SELECT 
    column_name,
    data_type,
    column_default,
    CASE 
        WHEN column_name = 'role' AND column_default LIKE '%user%' THEN '✅ Rôle par défaut user'
        WHEN column_name = 'role' THEN '⚠️ Rôle par défaut incorrect'
        ELSE '❌ Colonne role manquante'
    END as status
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'role';

-- Test 9: Vérifier les contraintes sur les rôles (user, driver, admin)
SELECT 'Test 9: Contraintes sur les rôles' as test_name;

SELECT 
    constraint_name,
    constraint_type,
    CASE 
        WHEN constraint_type = 'CHECK' AND constraint_name LIKE '%role%' THEN '✅ Contrainte CHECK sur role (user, driver, admin)'
        ELSE '⚠️ Contrainte CHECK manquante'
    END as status
FROM information_schema.table_constraints 
WHERE table_name = 'users' 
AND constraint_type = 'CHECK'
AND constraint_name LIKE '%role%';

-- Test 10: Résumé des tests
SELECT 'Test 10: Résumé' as test_name;

SELECT 
    'Système de portefeuille' as component,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wallets') 
        AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wallet_transactions')
        THEN '✅ Configuré correctement'
        ELSE '❌ Tables manquantes'
    END as status;

SELECT 
    'Devises supportées' as component,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'wallets' 
            AND column_name = 'currency' 
            AND column_default = '''USD''::character varying'
        ) THEN '✅ USD et CDF supportés'
        ELSE '❌ Devises non configurées'
    END as status;

SELECT 
    'Rôles utilisateur' as component,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'users' 
            AND column_name = 'role'
        ) THEN '✅ Rôles configurés'
        ELSE '❌ Rôles non configurés'
    END as status;

-- Message de fin
SELECT '🎉 Tests terminés ! Vérifiez les résultats ci-dessus.' as message;
