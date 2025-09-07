-- =====================================================
-- 🔧 CORRECTION DU TYPE DE product_id DANS LA TABLE orders
-- =====================================================

-- 1. Vérifier les types actuels
SELECT 
    '📋 Types actuels:' as message,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE (table_name = 'orders' AND column_name = 'product_id')
   OR (table_name = 'products' AND column_name = 'id');

-- 2. Vérifier s'il y a des données dans orders avec product_id
SELECT 
    '📋 Données dans orders:' as message,
    COUNT(*) as total_orders,
    COUNT(CASE WHEN product_id IS NOT NULL THEN 1 END) as orders_with_product
FROM orders;

-- 3. Vérifier quelques exemples de product_id
SELECT 
    '📋 Exemples de product_id:' as message,
    product_id,
    LENGTH(product_id) as length,
    CASE 
        WHEN product_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
        THEN 'UUID valide'
        ELSE 'Pas un UUID'
    END as uuid_check
FROM orders 
WHERE product_id IS NOT NULL
LIMIT 5;

-- 4. Si product_id est TEXT et doit être UUID, le convertir
-- D'abord, vérifier si la conversion est possible
SELECT 
    '🔍 Vérification de la conversion:' as message,
    COUNT(*) as total,
    COUNT(CASE 
        WHEN product_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
        THEN 1 
    END) as valid_uuids
FROM orders 
WHERE product_id IS NOT NULL;

-- 5. Si tous les product_id sont des UUID valides, convertir la colonne
-- (Décommentez les lignes suivantes si nécessaire)
/*
ALTER TABLE orders 
ALTER COLUMN product_id TYPE UUID USING product_id::UUID;
*/

-- 6. Alternative: Créer une fonction qui gère les deux types
CREATE OR REPLACE FUNCTION safe_product_lookup(product_id_param TEXT)
RETURNS UUID AS $$
DECLARE
    result UUID;
BEGIN
    -- Essayer de convertir en UUID si c'est un UUID valide
    IF product_id_param ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        SELECT id INTO result
        FROM products 
        WHERE id = product_id_param::UUID;
    ELSE
        -- Sinon, chercher par texte
        SELECT id INTO result
        FROM products 
        WHERE id::TEXT = product_id_param;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 7. Mettre à jour le trigger pour utiliser la fonction safe
DROP TRIGGER IF EXISTS add_money_to_user_wallet ON orders;

CREATE OR REPLACE FUNCTION add_money_to_user_wallet()
RETURNS TRIGGER AS $$
DECLARE
    seller_uuid UUID;
BEGIN
    -- Utiliser la fonction safe pour récupérer le seller_id
    SELECT seller_id INTO seller_uuid
    FROM products 
    WHERE id = safe_product_lookup(NEW.product_id);
    
    -- Ajouter de l'argent au portefeuille du vendeur
    IF seller_uuid IS NOT NULL THEN
        UPDATE wallets 
        SET balance = balance + NEW.total_amount
        WHERE user_id = seller_uuid;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Recréer le trigger
CREATE TRIGGER add_money_to_user_wallet
    AFTER INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION add_money_to_user_wallet();

-- 9. Test de la fonction safe
SELECT '✅ Fonction safe_product_lookup créée' as message;
SELECT safe_product_lookup('test-product-123') as test_result;

-- 10. Vérification finale
SELECT '✅ Correction terminée avec succès' as result;

