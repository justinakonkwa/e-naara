-- =====================================================
-- 💰 DIAGNOSTIC SIMPLE DU PORTEFEUILLE
-- =====================================================

-- 1. Vérifier la commande livrée
SELECT 
    'Commande livree:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    total_amount,
    driver_id,
    product_id,
    delivered_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '211e4a65';

-- 2. Vérifier le produit et son vendeur
SELECT 
    'Produit de la commande:' as message,
    p.id,
    p.name,
    p.seller_id as product_seller_id,
    p.price
FROM products p
WHERE p.id::TEXT = (
    SELECT product_id 
    FROM orders 
    WHERE LEFT(id::TEXT, 8) = '211e4a65'
);

-- 3. Vérifier tous les portefeuilles
SELECT 
    'Tous les portefeuilles:' as message,
    user_id,
    balance
FROM wallets 
ORDER BY balance DESC;

-- 4. Vérifier le portefeuille du livreur spécifiquement
SELECT 
    'Portefeuille du livreur:' as message,
    user_id,
    balance
FROM wallets 
WHERE user_id = '1e87d033-767a-46e5-9764-df8f5c2a08ea';

-- 5. Vérifier le portefeuille du vendeur du produit
SELECT 
    'Portefeuille du vendeur du produit:' as message,
    w.user_id,
    w.balance
FROM wallets w
JOIN products p ON p.seller_id = w.user_id
WHERE p.id::TEXT = (
    SELECT product_id 
    FROM orders 
    WHERE LEFT(id::TEXT, 8) = '211e4a65'
);

-- 6. Vérifier le trigger actuel
SELECT 
    'Trigger actuel:' as message,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name = 'add_money_to_user_wallet_on_delivery';

-- 7. Message de diagnostic
SELECT 'Diagnostic simple du portefeuille termine' as result;

