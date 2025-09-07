-- =====================================================
-- 💰 CORRECTION DU TRIGGER WALLET POUR LE BON VENDEUR
-- =====================================================

-- 1. Supprimer l'ancien trigger et fonction
DROP FUNCTION IF EXISTS add_money_to_user_wallet() CASCADE;

-- 2. Créer une nouvelle fonction qui ajoute l'argent au VENDEUR du produit
CREATE OR REPLACE FUNCTION add_money_to_user_wallet()
RETURNS TRIGGER AS $$
DECLARE
    seller_uuid UUID;
    product_exists BOOLEAN;
    current_balance DECIMAL(10,2);
BEGIN
    -- Vérifier si le produit existe et a un vendeur valide
    SELECT EXISTS(
        SELECT 1 FROM products 
        WHERE id::TEXT = NEW.product_id 
        AND seller_id IS NOT NULL
        AND seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    ) INTO product_exists;
    
    IF product_exists THEN
        -- Récupérer le seller_id du produit (PAS le driver_id !)
        SELECT seller_id INTO seller_uuid
        FROM products 
        WHERE id::TEXT = NEW.product_id;
        
        -- Si on trouve un vendeur valide et que la commande est livrée, ajouter l'argent
        IF seller_uuid IS NOT NULL AND NEW.status = 'delivered' THEN
            -- Récupérer le solde actuel
            SELECT balance INTO current_balance
            FROM wallets 
            WHERE user_id = seller_uuid;
            
            -- Mettre à jour le portefeuille du VENDEUR (pas du livreur !)
            UPDATE wallets 
            SET balance = COALESCE(current_balance, 0) + NEW.total_amount
            WHERE user_id = seller_uuid;
            
            -- Log pour debug
            RAISE NOTICE 'Argent ajouté au portefeuille du VENDEUR: % pour la commande: % (vendeur: %, montant: %)', 
                NEW.total_amount, NEW.id, seller_uuid, NEW.total_amount;
        END IF;
    ELSE
        -- Log si le produit n'existe pas ou n'a pas de vendeur valide
        RAISE NOTICE 'Produit non trouvé ou vendeur invalide: %', NEW.product_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Recréer le trigger
CREATE TRIGGER add_money_to_user_wallet_on_delivery
    AFTER UPDATE ON orders
    FOR EACH ROW
    WHEN (OLD.status != 'delivered' AND NEW.status = 'delivered')
    EXECUTE FUNCTION add_money_to_user_wallet();

-- 4. Vérifier que le trigger a été créé
SELECT 
    'Trigger corrige:' as message,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name = 'add_money_to_user_wallet_on_delivery';

-- 5. Vérifier les portefeuilles avant test
SELECT 
    'Portefeuilles avant test:' as message,
    user_id,
    balance,
    CASE 
        WHEN user_id = '1e87d033-767a-46e5-9764-df8f5c2a08ea' THEN 'Livreur'
        ELSE 'Autre utilisateur'
    END as user_type
FROM wallets 
ORDER BY balance DESC;

-- 6. Créer un portefeuille pour le vendeur s'il n'existe pas
INSERT INTO wallets (user_id, balance, created_at, updated_at)
SELECT 
    p.seller_id,
    0,
    NOW(),
    NOW()
FROM products p
WHERE p.id::TEXT = (
    SELECT product_id 
    FROM orders 
    WHERE LEFT(id::TEXT, 8) = '211e4a65'
)
AND NOT EXISTS (
    SELECT 1 FROM wallets w WHERE w.user_id = p.seller_id
);

-- 7. Simuler une nouvelle livraison pour tester le trigger corrigé
SELECT 'Test du trigger corrige:' as test_message;

-- Remettre le statut à picked_up pour pouvoir tester
UPDATE orders 
SET 
    status = 'picked_up',
    updated_at = NOW(),
    delivered_at = NULL
WHERE LEFT(id::TEXT, 8) = '211e4a65';

-- Simuler la livraison pour déclencher le trigger
UPDATE orders 
SET 
    status = 'delivered',
    updated_at = NOW(),
    delivered_at = NOW()
WHERE LEFT(id::TEXT, 8) = '211e4a65';

-- 8. Vérifier les portefeuilles après test
SELECT 
    'Portefeuilles apres test:' as message,
    user_id,
    balance,
    CASE 
        WHEN user_id = '1e87d033-767a-46e5-9764-df8f5c2a08ea' THEN 'Livreur'
        WHEN user_id::TEXT = (
            SELECT seller_id::TEXT
            FROM products 
            WHERE id::TEXT = (
                SELECT product_id 
                FROM orders 
                WHERE LEFT(id::TEXT, 8) = '211e4a65'
            )
        ) THEN 'Vendeur du produit'
        ELSE 'Autre utilisateur'
    END as user_type
FROM wallets 
ORDER BY balance DESC;

-- 9. Vérifier le statut final de la commande
SELECT 
    'Statut final de la commande:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    total_amount,
    delivered_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '211e4a65';

-- 10. Message de succès
SELECT 'Trigger wallet corrige pour le bon vendeur' as result;
