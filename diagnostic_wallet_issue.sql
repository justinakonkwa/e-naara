-- =====================================================
-- 💰 DIAGNOSTIC DU PROBLÈME DE PORTEFEUILLE
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

-- 3. Vérifier les portefeuilles
SELECT 
    'Portefeuilles actuels:' as message,
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

-- 4. Vérifier le trigger actuel
SELECT 
    'Trigger actuel:' as message,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'add_money_to_user_wallet_on_delivery';

-- 5. Vérifier la fonction du trigger
SELECT 
    'Fonction du trigger:' as message,
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'add_money_to_user_wallet';

-- 6. Test manuel du trigger
SELECT 'Test manuel du trigger:' as test_message;

-- Vérifier le portefeuille du vendeur avant
SELECT 
    'Portefeuille vendeur avant:' as message,
    user_id,
    balance
FROM wallets 
WHERE user_id = (
    SELECT seller_id 
    FROM products 
    WHERE id::TEXT = (
        SELECT product_id 
        FROM orders 
        WHERE LEFT(id::TEXT, 8) = '211e4a65'
    )
);

-- 7. Message de diagnostic
SELECT 'Diagnostic du portefeuille termine' as result;
