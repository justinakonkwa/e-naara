-- =====================================================
-- 💰 CORRECTION DU TRIGGER WALLET POUR LA LIVRAISON
-- =====================================================

-- 1. Supprimer l'ancien trigger et fonction
DROP FUNCTION IF EXISTS add_money_to_user_wallet() CASCADE;

-- 2. Créer une nouvelle fonction qui fonctionne avec les types corrects
CREATE OR REPLACE FUNCTION add_money_to_user_wallet()
RETURNS TRIGGER AS $$
DECLARE
    seller_uuid UUID;
    product_exists BOOLEAN;
BEGIN
    -- Vérifier si le produit existe et récupérer le seller_id
    SELECT EXISTS(SELECT 1 FROM products WHERE id::TEXT = NEW.product_id) INTO product_exists;
    
    IF product_exists THEN
        -- Récupérer le seller_id du produit
        SELECT seller_id INTO seller_uuid
        FROM products 
        WHERE id::TEXT = NEW.product_id;
        
        -- Si on trouve un vendeur et que la commande est livrée, ajouter l'argent
        IF seller_uuid IS NOT NULL AND NEW.status = 'delivered' THEN
            UPDATE wallets 
            SET balance = balance + NEW.total_amount
            WHERE user_id = seller_uuid;
            
            -- Log pour debug
            RAISE NOTICE 'Argent ajouté au portefeuille: % pour la commande: %', NEW.total_amount, NEW.id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Créer le trigger sur UPDATE (pas INSERT) pour la livraison
CREATE TRIGGER add_money_to_user_wallet_on_delivery
    AFTER UPDATE ON orders
    FOR EACH ROW
    WHEN (OLD.status != 'delivered' AND NEW.status = 'delivered')
    EXECUTE FUNCTION add_money_to_user_wallet();

-- 4. Vérifier que le trigger a été créé
SELECT 
    'Trigger cree:' as message,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'add_money_to_user_wallet_on_delivery';

-- 5. Vérifier les portefeuilles existants
SELECT 
    'Portefeuilles existants:' as message,
    user_id,
    balance
FROM wallets 
LIMIT 5;

-- 6. Test de la fonction avec une commande existante
SELECT 'Test de la fonction wallet:' as test_message;

-- Vérifier le statut actuel de la commande
SELECT 
    'Statut actuel de la commande:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    product_id,
    total_amount
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- 7. Simuler une livraison pour tester le trigger
UPDATE orders 
SET 
    status = 'delivered',
    updated_at = NOW(),
    delivered_at = NOW()
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- 8. Vérifier le résultat de la livraison
SELECT 
    'Resultat de la livraison:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    delivered_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae';

-- 9. Vérifier si l'argent a été ajouté au portefeuille
SELECT 
    'Portefeuilles apres livraison:' as message,
    user_id,
    balance
FROM wallets 
ORDER BY balance DESC
LIMIT 5;

-- 10. Message de succès
SELECT 'Trigger wallet corrige pour la livraison' as result;

