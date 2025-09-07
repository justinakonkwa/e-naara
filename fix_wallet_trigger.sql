-- =====================================================
-- 🔧 CORRECTION DU TRIGGER add_money_to_user_wallet
-- =====================================================

-- 1. Vérifier le trigger existant
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'add_money_to_user_wallet';

-- 2. Désactiver temporairement le trigger problématique
DROP TRIGGER IF EXISTS add_money_to_user_wallet ON orders;

-- 3. Recréer le trigger avec la correction de type
CREATE OR REPLACE FUNCTION add_money_to_user_wallet()
RETURNS TRIGGER AS $$
BEGIN
    -- Ajouter de l'argent au portefeuille du vendeur
    UPDATE wallets 
    SET balance = balance + NEW.total_amount
    WHERE user_id = (
        SELECT seller_id 
        FROM products 
        WHERE id::TEXT = NEW.product_id  -- Conversion explicite UUID vers TEXT
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Recréer le trigger
CREATE TRIGGER add_money_to_user_wallet
    AFTER INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION add_money_to_user_wallet();

-- 5. Vérifier que le trigger a été recréé
SELECT 
    '✅ Trigger recréé:' as message,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name = 'add_money_to_user_wallet';

-- 6. Vérifier la structure de la table products
SELECT 
    '📋 Structure de la table products:' as message,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name IN ('id', 'seller_id')
ORDER BY ordinal_position;

-- 7. Vérifier la structure de la table orders
SELECT 
    '📋 Structure de la table orders:' as message,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name IN ('id', 'product_id', 'user_id')
ORDER BY ordinal_position;

-- 8. Test de la fonction corrigée
SELECT '✅ Trigger add_money_to_user_wallet corrigé avec succès' as result;

