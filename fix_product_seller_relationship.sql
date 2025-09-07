-- =====================================================
-- 🔧 CORRECTION DE LA RELATION PRODUIT-VENDEUR ET TRIGGER WALLET
-- =====================================================

-- 1. Vérifier les produits et leurs vendeurs
SELECT 
    'Produits et leurs vendeurs:' as message,
    id,
    name,
    seller_id,
    CASE 
        WHEN seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
        THEN 'UUID valide'
        ELSE 'UUID invalide'
    END as uuid_check
FROM products 
ORDER BY created_at DESC
LIMIT 10;

-- 2. Vérifier les commandes et leurs produits
SELECT 
    'Commandes et leurs produits:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    product_id,
    total_amount,
    status,
    CASE 
        WHEN product_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
        THEN 'UUID valide'
        ELSE 'UUID invalide'
    END as uuid_check
FROM orders 
ORDER BY created_at DESC
LIMIT 10;

-- 3. Corriger le produit test-product-123 pour qu'il ait un vendeur valide
UPDATE products 
SET seller_id = '1e87d033-767a-46e5-9764-df8f5c2a08ea'::UUID
WHERE id = 'test-product-123';

-- 4. Vérifier la correction
SELECT 
    'Produit corrige:' as message,
    id,
    name,
    seller_id
FROM products 
WHERE id = 'test-product-123';

-- 5. Corriger le trigger pour gérer les cas d'erreur
DROP FUNCTION IF EXISTS add_money_to_user_wallet() CASCADE;

CREATE OR REPLACE FUNCTION add_money_to_user_wallet()
RETURNS TRIGGER AS $$
DECLARE
    seller_uuid UUID;
    product_exists BOOLEAN;
BEGIN
    -- Vérifier si le produit existe et a un vendeur valide
    SELECT EXISTS(
        SELECT 1 FROM products 
        WHERE id::TEXT = NEW.product_id 
        AND seller_id IS NOT NULL
        AND seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    ) INTO product_exists;
    
    IF product_exists THEN
        -- Récupérer le seller_id du produit
        SELECT seller_id INTO seller_uuid
        FROM products 
        WHERE id::TEXT = NEW.product_id;
        
        -- Si on trouve un vendeur valide et que la commande est livrée, ajouter l'argent
        IF seller_uuid IS NOT NULL AND NEW.status = 'delivered' THEN
            UPDATE wallets 
            SET balance = balance + NEW.total_amount
            WHERE user_id = seller_uuid;
            
            -- Log pour debug
            RAISE NOTICE 'Argent ajouté au portefeuille: % pour la commande: % (vendeur: %)', 
                NEW.total_amount, NEW.id, seller_uuid;
        END IF;
    ELSE
        -- Log si le produit n'existe pas ou n'a pas de vendeur valide
        RAISE NOTICE 'Produit non trouvé ou vendeur invalide: %', NEW.product_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Recréer le trigger
CREATE TRIGGER add_money_to_user_wallet_on_delivery
    AFTER UPDATE ON orders
    FOR EACH ROW
    WHEN (OLD.status != 'delivered' AND NEW.status = 'delivered')
    EXECUTE FUNCTION add_money_to_user_wallet();

-- 7. Vérifier que le trigger a été créé
SELECT 
    'Trigger cree:' as message,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name = 'add_money_to_user_wallet_on_delivery';

-- 8. Vérifier les portefeuilles avant test
SELECT 
    'Portefeuilles avant test:' as message,
    user_id,
    balance
FROM wallets 
ORDER BY balance DESC
LIMIT 5;

-- 9. Test de livraison avec la commande corrigée
SELECT 'Test de livraison avec produit corrige:' as test_message;

-- Vérifier le statut actuel
SELECT 
    'Statut actuel:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    product_id,
    total_amount
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- Simuler la livraison
UPDATE orders 
SET 
    status = 'delivered',
    updated_at = NOW(),
    delivered_at = NOW()
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- 10. Vérifier le résultat
SELECT 
    'Resultat de la livraison:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    delivered_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- 11. Vérifier les portefeuilles après test
SELECT 
    'Portefeuilles apres test:' as message,
    user_id,
    balance
FROM wallets 
ORDER BY balance DESC
LIMIT 5;

-- 12. Message de succès
SELECT 'Relation produit-vendeur et trigger wallet corriges' as result;

