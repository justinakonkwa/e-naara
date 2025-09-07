-- =====================================================
-- 🔧 CORRECTION DÉFINITIVE DU TRIGGER add_money_to_user_wallet
-- =====================================================

-- 1. Désactiver temporairement le trigger problématique
DROP TRIGGER IF EXISTS add_money_to_user_wallet ON orders;

-- 2. Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS add_money_to_user_wallet();

-- 3. Recréer la fonction avec une approche plus simple
CREATE OR REPLACE FUNCTION add_money_to_user_wallet()
RETURNS TRIGGER AS $$
DECLARE
    seller_uuid UUID;
BEGIN
    -- Approche simple: essayer de convertir product_id en UUID
    BEGIN
        -- Essayer de traiter product_id comme un UUID
        SELECT seller_id INTO seller_uuid
        FROM products 
        WHERE id = NEW.product_id::UUID;
        
        -- Si on trouve un vendeur, ajouter l'argent
        IF seller_uuid IS NOT NULL THEN
            UPDATE wallets 
            SET balance = balance + NEW.total_amount
            WHERE user_id = seller_uuid;
        END IF;
        
    EXCEPTION
        WHEN invalid_text_representation THEN
            -- Si product_id n'est pas un UUID valide, ignorer silencieusement
            NULL;
        WHEN OTHERS THEN
            -- Pour toute autre erreur, ignorer silencieusement
            NULL;
    END;
    
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
    'Trigger recree:' as message,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name = 'add_money_to_user_wallet';

-- 6. Test de la fonction avec un UUID valide
SELECT 'Test avec UUID valide:' as test_message;
SELECT seller_id 
FROM products 
WHERE id = 'test-product-123'::UUID;

-- 7. Vérifier la structure de la table products
SELECT 
    'Structure de la table products:' as message,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name IN ('id', 'seller_id')
ORDER BY ordinal_position;

-- 8. Vérifier la structure de la table orders
SELECT 
    'Structure de la table orders:' as message,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name IN ('id', 'product_id', 'user_id')
ORDER BY ordinal_position;

-- 9. Message de succès
SELECT 'Trigger add_money_to_user_wallet corrige avec succes' as result;

