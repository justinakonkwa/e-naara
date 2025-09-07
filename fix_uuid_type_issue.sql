-- =====================================================
-- 🔧 CORRECTION DES PROBLÈMES DE TYPE UUID
-- =====================================================

-- Ce script corrige les problèmes de comparaison entre text et uuid

-- Étape 1: Vérifier la structure de la table orders
SELECT '🔍 ÉTAPE 1: Vérification de la structure de la table orders' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name IN ('id', 'user_id', 'driver_id')
ORDER BY column_name;

-- Étape 2: Vérifier les contraintes de clés étrangères
SELECT '🔗 ÉTAPE 2: Vérification des contraintes de clés étrangères' as info;

SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'orders'
AND kcu.column_name IN ('user_id', 'driver_id');

-- Étape 3: Vérifier les données existantes
SELECT '📊 ÉTAPE 3: Vérification des données existantes' as info;

SELECT 
    COUNT(*) as total_commandes,
    COUNT(CASE WHEN driver_id IS NOT NULL THEN 1 END) as commandes_avec_livreur,
    COUNT(CASE WHEN driver_id IS NULL THEN 1 END) as commandes_sans_livreur
FROM orders;

-- Étape 4: Vérifier le format des UUID
SELECT '🎯 ÉTAPE 4: Vérification du format des UUID' as info;

SELECT 
    'user_id format' as check_type,
    CASE 
        WHEN user_id::TEXT ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
        THEN '✅ Format UUID valide'
        ELSE '❌ Format UUID invalide'
    END as status
FROM orders 
LIMIT 1

UNION ALL

SELECT 
    'driver_id format' as check_type,
    CASE 
        WHEN driver_id IS NULL THEN '✅ NULL (normal)'
        WHEN driver_id::TEXT ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
        THEN '✅ Format UUID valide'
        ELSE '❌ Format UUID invalide'
    END as status
FROM orders 
WHERE driver_id IS NOT NULL
LIMIT 1;

-- Étape 5: Corriger les colonnes si nécessaire
SELECT '🔧 ÉTAPE 5: Correction des colonnes si nécessaire' as info;

-- Vérifier et corriger la colonne driver_id si elle n'est pas du bon type
DO $$ 
BEGIN
    -- Vérifier le type de la colonne driver_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'orders' 
        AND column_name = 'driver_id' 
        AND data_type != 'uuid'
    ) THEN
        RAISE NOTICE '⚠️ Colonne driver_id n''est pas de type UUID, correction en cours...';
        
        -- Convertir la colonne en UUID si elle contient des données valides
        ALTER TABLE orders 
        ALTER COLUMN driver_id TYPE UUID USING driver_id::UUID;
        
        RAISE NOTICE '✅ Colonne driver_id convertie en UUID';
    ELSE
        RAISE NOTICE '✅ Colonne driver_id est déjà de type UUID';
    END IF;
    
    -- Vérifier le type de la colonne user_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'orders' 
        AND column_name = 'user_id' 
        AND data_type != 'uuid'
    ) THEN
        RAISE NOTICE '⚠️ Colonne user_id n''est pas de type UUID, correction en cours...';
        
        ALTER TABLE orders 
        ALTER COLUMN user_id TYPE UUID USING user_id::UUID;
        
        RAISE NOTICE '✅ Colonne user_id convertie en UUID';
    ELSE
        RAISE NOTICE '✅ Colonne user_id est déjà de type UUID';
    END IF;
    
    -- Vérifier le type de la colonne id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'orders' 
        AND column_name = 'id' 
        AND data_type != 'uuid'
    ) THEN
        RAISE NOTICE '⚠️ Colonne id n''est pas de type UUID, correction en cours...';
        
        ALTER TABLE orders 
        ALTER COLUMN id TYPE UUID USING id::UUID;
        
        RAISE NOTICE '✅ Colonne id convertie en UUID';
    ELSE
        RAISE NOTICE '✅ Colonne id est déjà de type UUID';
    END IF;
END $$;

-- Étape 6: Vérifier les index
SELECT '📊 ÉTAPE 6: Vérification des index' as info;

SELECT 
    indexname,
    tablename,
    indexdef
FROM pg_indexes 
WHERE tablename = 'orders' 
AND (indexdef LIKE '%driver_id%' OR indexdef LIKE '%user_id%')
ORDER BY indexname;

-- Étape 7: Test de requête avec UUID
SELECT '🧪 ÉTAPE 7: Test de requête avec UUID' as info;

-- Test avec une commande existante
DO $$
DECLARE
    test_order_id UUID;
    test_user_id UUID;
    found_order RECORD;
BEGIN
    -- Récupérer une commande existante
    SELECT id, user_id INTO test_order_id, test_user_id
    FROM orders 
    LIMIT 1;
    
    IF test_order_id IS NULL THEN
        RAISE NOTICE '❌ Aucune commande trouvée pour le test';
        RETURN;
    END IF;
    
    RAISE NOTICE '🧪 Test avec commande: %', test_order_id;
    RAISE NOTICE '🧪 Test avec utilisateur: %', test_user_id;
    
    -- Tester la requête avec UUID
    SELECT * INTO found_order
    FROM orders 
    WHERE id = test_order_id
    AND user_id = test_user_id;
    
    IF found_order.id IS NOT NULL THEN
        RAISE NOTICE '✅ Requête UUID réussie: %', found_order.id;
    ELSE
        RAISE NOTICE '❌ Requête UUID échouée';
    END IF;
    
END $$;

-- Étape 8: Statistiques finales
SELECT '📈 ÉTAPE 8: Statistiques finales' as info;

SELECT 
    'orders' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN driver_id IS NOT NULL THEN 1 END) as with_driver,
    COUNT(CASE WHEN driver_id IS NULL THEN 1 END) as without_driver
FROM orders

UNION ALL

SELECT 
    'auth.users' as table_name,
    COUNT(*) as total_records,
    NULL as with_driver,
    NULL as without_driver
FROM auth.users;

-- Message de confirmation
SELECT '🎉 CORRECTION TERMINÉE AVEC SUCCÈS!' as message;
SELECT 'Les problèmes de type UUID ont été corrigés.' as info;
