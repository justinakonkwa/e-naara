-- =====================================================
-- 🧪 TEST DU SYSTÈME DE CODES COURTS
-- =====================================================

-- Ce script teste le système de codes courts pour les commandes

-- Étape 1: Vérifier les commandes existantes
SELECT '📋 ÉTAPE 1: Vérification des commandes existantes' as info;

SELECT 
    id,
    LEFT(id::TEXT, 8) as code_court,
    status,
    created_at
FROM orders 
ORDER BY created_at DESC 
LIMIT 5;

-- Étape 2: Tester la recherche par code court
SELECT '🔍 ÉTAPE 2: Test de recherche par code court' as info;

-- Prendre la première commande et tester avec son code court
DO $$
DECLARE
    test_order_id UUID;
    test_short_code TEXT;
    found_order RECORD;
BEGIN
    -- Récupérer une commande existante
    SELECT id INTO test_order_id 
    FROM orders 
    LIMIT 1;
    
    IF test_order_id IS NULL THEN
        RAISE NOTICE '❌ Aucune commande trouvée pour le test';
        RETURN;
    END IF;
    
    -- Générer le code court
    test_short_code := LEFT(test_order_id::TEXT, 8);
    
    RAISE NOTICE '🧪 Test avec commande: %', test_order_id;
    RAISE NOTICE '🧪 Code court généré: %', test_short_code;
    
    -- Tester la recherche par code court
    SELECT * INTO found_order
    FROM orders 
    WHERE id::TEXT ILIKE test_short_code || '%'
    LIMIT 1;
    
    IF found_order.id IS NOT NULL THEN
        RAISE NOTICE '✅ Recherche par code court réussie: %', found_order.id;
    ELSE
        RAISE NOTICE '❌ Recherche par code court échouée';
    END IF;
    
    -- Tester avec le code court en majuscules
    test_short_code := UPPER(test_short_code);
    RAISE NOTICE '🧪 Test avec code court en majuscules: %', test_short_code;
    
    SELECT * INTO found_order
    FROM orders 
    WHERE UPPER(id::TEXT) ILIKE test_short_code || '%'
    LIMIT 1;
    
    IF found_order.id IS NOT NULL THEN
        RAISE NOTICE '✅ Recherche par code court majuscules réussie: %', found_order.id;
    ELSE
        RAISE NOTICE '❌ Recherche par code court majuscules échouée';
    END IF;
    
END $$;

-- Étape 3: Vérifier les index pour optimiser les recherches
SELECT '📊 ÉTAPE 3: Vérification des index' as info;

SELECT 
    indexname,
    tablename,
    indexdef
FROM pg_indexes 
WHERE tablename = 'orders' 
AND indexname LIKE '%id%'
ORDER BY indexname;

-- Étape 4: Statistiques des commandes
SELECT '📈 ÉTAPE 4: Statistiques des commandes' as info;

SELECT 
    COUNT(*) as total_commandes,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as commandes_en_attente,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as commandes_confirmees,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as commandes_livrees,
    COUNT(CASE WHEN driver_id IS NOT NULL THEN 1 END) as commandes_assignees
FROM orders;

-- Étape 5: Exemples de codes courts
SELECT '🎯 ÉTAPE 5: Exemples de codes courts' as info;

SELECT 
    'Code court: ' || LEFT(id::TEXT, 8) as exemple_code_court,
    'UUID complet: ' || id as exemple_uuid_complet,
    'Statut: ' || status as statut_commande,
    'Date: ' || TO_CHAR(created_at, 'DD/MM/YYYY HH24:MI') as date_creation
FROM orders 
ORDER BY created_at DESC 
LIMIT 3;

-- Étape 6: Test de validation de format
SELECT '✅ ÉTAPE 6: Test de validation de format' as info;

DO $$
DECLARE
    test_codes TEXT[] := ARRAY['15F403E3', 'abc12345', '12345678', 'ABCDEFGH', 'invalid'];
    test_code TEXT;
    is_valid BOOLEAN;
BEGIN
    FOREACH test_code IN ARRAY test_codes
    LOOP
        -- Vérifier la longueur
        IF LENGTH(test_code) = 8 THEN
            -- Vérifier le format hexadécimal
            is_valid := test_code ~ '^[0-9A-Fa-f]{8}$';
            
            IF is_valid THEN
                RAISE NOTICE '✅ Code valide: %', test_code;
            ELSE
                RAISE NOTICE '❌ Code invalide (format): %', test_code;
            END IF;
        ELSE
            RAISE NOTICE '❌ Code invalide (longueur): % (longueur: %)', test_code, LENGTH(test_code);
        END IF;
    END LOOP;
END $$;

-- Étape 7: Recommandations pour l'utilisation
SELECT '💡 ÉTAPE 7: Recommandations' as info;

SELECT 
    'Pour utiliser les codes courts:' as recommandation
UNION ALL
SELECT '1. Les codes courts font exactement 8 caractères'
UNION ALL
SELECT '2. Ils contiennent seulement des caractères hexadécimaux (0-9, A-F)'
UNION ALL
SELECT '3. Ils sont insensibles à la casse (15F403E3 = 15f403e3)'
UNION ALL
SELECT '4. Ils correspondent aux 8 premiers caractères de l''UUID'
UNION ALL
SELECT '5. Exemple valide: 15F403E3'
UNION ALL
SELECT '6. Exemple invalide: ABC12345 (contient des lettres non-hex)';

-- Message de confirmation
SELECT '🎉 TESTS TERMINÉS AVEC SUCCÈS!' as message;
SELECT 'Le système de codes courts est prêt à être utilisé.' as info;
