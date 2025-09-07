-- Script de diagnostic simple pour identifier le problème
-- À exécuter dans l'interface Supabase SQL Editor

-- 1. Vérifier l'état du produit problématique
SELECT 
    id,
    name,
    price,
    quantity,
    is_available,
    seller_id,
    created_at,
    updated_at
FROM products 
WHERE id = '1755205022966';

-- 2. Vérifier tous les produits récents
SELECT 
    id,
    name,
    quantity,
    is_available,
    seller_id
FROM products 
ORDER BY created_at DESC
LIMIT 5;

-- 3. Vérifier les triggers existants sur la table orders
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;

-- 4. Vérifier les fonctions existantes
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%product%'
ORDER BY routine_name;

-- 5. Tester manuellement la logique de disponibilité
DO $$
DECLARE
    product_record RECORD;
    product_id TEXT := '1755205022966';
    requested_quantity INTEGER := 1;
BEGIN
    -- Récupérer les informations du produit
    SELECT * INTO product_record 
    FROM products 
    WHERE id = product_id;
    
    -- Afficher les informations
    RAISE NOTICE '=== DIAGNOSTIC DU PRODUIT ===';
    RAISE NOTICE 'ID: %', product_record.id;
    RAISE NOTICE 'Nom: %', product_record.name;
    RAISE NOTICE 'Quantité en stock: %', product_record.quantity;
    RAISE NOTICE 'Disponible: %', product_record.is_available;
    RAISE NOTICE 'Quantité demandée: %', requested_quantity;
    
    -- Tester chaque condition
    IF product_record.id IS NULL THEN
        RAISE NOTICE '❌ PROBLÈME: Le produit n''existe pas';
    ELSE
        RAISE NOTICE '✅ Le produit existe';
    END IF;
    
    IF NOT product_record.is_available THEN
        RAISE NOTICE '❌ PROBLÈME: Le produit n''est pas disponible (is_available = false)';
    ELSE
        RAISE NOTICE '✅ Le produit est disponible';
    END IF;
    
    IF product_record.quantity < requested_quantity THEN
        RAISE NOTICE '❌ PROBLÈME: Quantité insuffisante. Stock: %, Demandé: %', 
            product_record.quantity, requested_quantity;
    ELSE
        RAISE NOTICE '✅ Quantité suffisante';
    END IF;
    
    RAISE NOTICE '=== FIN DU DIAGNOSTIC ===';
END $$;
