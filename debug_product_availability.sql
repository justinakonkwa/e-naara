-- Script de diagnostic pour vérifier la disponibilité du produit
-- Remplacer '1755205022966' par l'ID du produit à vérifier

-- 1. Vérifier les informations du produit
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

-- 2. Vérifier si le produit existe
SELECT COUNT(*) as product_exists
FROM products 
WHERE id = '1755205022966';

-- 3. Vérifier tous les produits pour voir s'il y a un problème général
SELECT 
    id,
    name,
    quantity,
    is_available,
    seller_id
FROM products 
ORDER BY created_at DESC
LIMIT 10;

-- 4. Vérifier les triggers existants
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;

-- 5. Vérifier les fonctions existantes
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%product%'
ORDER BY routine_name;

-- 6. Tester la fonction check_product_availability manuellement
-- (Cette requête simule ce que fait le trigger)
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
    
    -- Afficher les informations pour debug
    RAISE NOTICE 'Produit trouvé: %', product_record.id;
    RAISE NOTICE 'Nom: %', product_record.name;
    RAISE NOTICE 'Quantité en stock: %', product_record.quantity;
    RAISE NOTICE 'Disponible: %', product_record.is_available;
    RAISE NOTICE 'Quantité demandée: %', requested_quantity;
    
    -- Vérifier la disponibilité
    IF product_record.id IS NULL THEN
        RAISE EXCEPTION 'Le produit % n''existe pas', product_id;
    END IF;
    
    IF NOT product_record.is_available THEN
        RAISE EXCEPTION 'Le produit % n''est pas disponible (is_available = false)', product_id;
    END IF;
    
    IF product_record.quantity < requested_quantity THEN
        RAISE EXCEPTION 'Le produit % n''a pas assez de stock. Stock: %, Demandé: %', 
            product_id, product_record.quantity, requested_quantity;
    END IF;
    
    RAISE NOTICE 'Le produit % est disponible pour la commande!', product_id;
END $$;
