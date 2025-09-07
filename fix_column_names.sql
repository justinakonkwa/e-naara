-- Script pour corriger les noms de colonnes dans les triggers
-- Le problème : la colonne s'appelle 'stock_quantity' et non 'quantity'

-- 1. Supprimer tous les triggers existants
DROP TRIGGER IF EXISTS check_product_availability_trigger ON orders;
DROP TRIGGER IF EXISTS update_product_quantity_trigger ON orders;
DROP TRIGGER IF EXISTS restore_product_quantity_trigger ON orders;

-- 2. Corriger la fonction check_product_availability
CREATE OR REPLACE FUNCTION check_product_availability()
RETURNS TRIGGER AS $$
DECLARE
    product_record RECORD;
BEGIN
    -- Récupérer les informations du produit
    SELECT * INTO product_record
    FROM products 
    WHERE id = NEW.product_id;
    
    -- Vérifier si le produit existe
    IF product_record.id IS NULL THEN
        RAISE EXCEPTION 'Le produit % n''existe pas', NEW.product_id;
    END IF;
    
    -- Vérifier si le produit est disponible
    IF NOT product_record.is_available THEN
        RAISE EXCEPTION 'Le produit % n''est pas disponible (is_available = false)', NEW.product_id;
    END IF;
    
    -- Vérifier si la quantité en stock est suffisante (CORRIGÉ: stock_quantity)
    IF product_record.stock_quantity < NEW.quantity THEN
        RAISE EXCEPTION 'Quantité insuffisante pour le produit %. Stock disponible: %, Quantité demandée: %', 
            NEW.product_id, product_record.stock_quantity, NEW.quantity;
    END IF;
    
    -- Vérifier que la quantité demandée est positive
    IF NEW.quantity <= 0 THEN
        RAISE EXCEPTION 'La quantité demandée doit être positive (actuelle: %)', NEW.quantity;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 3. Corriger la fonction update_product_quantity_on_sale
CREATE OR REPLACE FUNCTION update_product_quantity_on_sale()
RETURNS TRIGGER AS $$
DECLARE
    current_quantity INTEGER;
    order_quantity INTEGER;
BEGIN
    -- Récupérer la quantité actuelle du produit (CORRIGÉ: stock_quantity)
    SELECT stock_quantity INTO current_quantity
    FROM products
    WHERE id = NEW.product_id;
    
    -- Récupérer la quantité commandée
    order_quantity := NEW.quantity;
    
    -- Vérifier si la quantité est suffisante
    IF current_quantity < order_quantity THEN
        RAISE EXCEPTION 'Quantité insuffisante pour le produit % (disponible: %, demandée: %)', 
            NEW.product_id, current_quantity, order_quantity;
    END IF;
    
    -- Décrémenter la quantité du produit (CORRIGÉ: stock_quantity)
    UPDATE products 
    SET stock_quantity = stock_quantity - order_quantity,
        updated_at = NOW()
    WHERE id = NEW.product_id;
    
    -- Si la quantité devient 0, marquer le produit comme indisponible
    IF (current_quantity - order_quantity) <= 0 THEN
        UPDATE products 
        SET is_available = false,
            updated_at = NOW()
        WHERE id = NEW.product_id;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 4. Corriger la fonction restore_product_quantity_on_cancel
CREATE OR REPLACE FUNCTION restore_product_quantity_on_cancel()
RETURNS TRIGGER AS $$
DECLARE
    order_quantity INTEGER;
BEGIN
    -- Si la commande est annulée ou remboursée
    IF NEW.status IN ('cancelled', 'refunded') AND OLD.status NOT IN ('cancelled', 'refunded') THEN
        -- Récupérer la quantité de la commande
        order_quantity := NEW.quantity;
        
        -- Restaurer la quantité du produit (CORRIGÉ: stock_quantity)
        UPDATE products 
        SET stock_quantity = stock_quantity + order_quantity,
            is_available = true,
            updated_at = NOW()
        WHERE id = NEW.product_id;
        
        -- Ajouter une transaction de remboursement dans le portefeuille
        INSERT INTO wallet_transactions (
            wallet_id, type, amount, description, order_id, status
        ) SELECT 
            w.id, 'refund', NEW.total_amount, 
            'Remboursement - Commande annulée #' || NEW.id, NEW.id, 'completed'
        FROM wallets w
        WHERE w.user_id = NEW.user_id;
        
        -- Débiter le portefeuille du vendeur (remboursement de la commission)
        UPDATE wallets 
        SET balance = balance - (NEW.total_amount * 0.90),
            updated_at = NOW()
        WHERE user_id IN (
            SELECT seller_id FROM products WHERE id = NEW.product_id
        );
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 5. Recréer tous les triggers
CREATE TRIGGER check_product_availability_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION check_product_availability();

CREATE TRIGGER update_product_quantity_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_product_quantity_on_sale();

CREATE TRIGGER restore_product_quantity_trigger
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION restore_product_quantity_on_cancel();

-- 6. Vérifier la structure de la table products
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'products'
AND column_name IN ('id', 'name', 'price', 'stock_quantity', 'is_available', 'seller_id')
ORDER BY ordinal_position;

-- 7. Tester avec le produit problématique
DO $$
DECLARE
    product_record RECORD;
    product_id TEXT := '1755205022966';
    requested_quantity INTEGER := 2;
BEGIN
    -- Récupérer les informations du produit
    SELECT * INTO product_record 
    FROM products 
    WHERE id = product_id;
    
    -- Afficher les informations
    RAISE NOTICE '=== TEST APRÈS CORRECTION ===';
    RAISE NOTICE 'ID: %', product_record.id;
    RAISE NOTICE 'Nom: %', product_record.name;
    RAISE NOTICE 'Stock quantity: %', product_record.stock_quantity;
    RAISE NOTICE 'Disponible: %', product_record.is_available;
    RAISE NOTICE 'Quantité demandée: %', requested_quantity;
    
    -- Tester la logique
    IF product_record.id IS NULL THEN
        RAISE NOTICE 'ERREUR: Le produit n''existe pas';
    ELSIF NOT product_record.is_available THEN
        RAISE NOTICE 'ERREUR: Le produit n''est pas disponible';
    ELSIF product_record.stock_quantity < requested_quantity THEN
        RAISE NOTICE 'ERREUR: Quantité insuffisante. Stock: %, Demandé: %', 
            product_record.stock_quantity, requested_quantity;
    ELSE
        RAISE NOTICE 'SUCCES: Le produit est disponible!';
    END IF;
END $$;

-- =====================================================
-- 🚀 CONVERSION DES PRODUITS EN USD ET AJOUT DE LA COLONNE DEVISE
-- =====================================================

-- Étape 1: Ajouter la colonne currency à la table products
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'currency') THEN
        ALTER TABLE products ADD COLUMN currency VARCHAR(3) DEFAULT 'USD' NOT NULL CHECK (currency IN ('USD', 'EUR', 'CDF'));
        RAISE NOTICE 'Colonne currency ajoutée à la table products';
    ELSE
        RAISE NOTICE 'Colonne currency existe déjà dans la table products';
    END IF;
END $$;

-- Étape 2: Convertir tous les prix existants d'EUR vers USD (taux approximatif 1 EUR = 1.08 USD)
UPDATE products 
SET 
    price = ROUND((price * 1.08)::DECIMAL(10,2), 2),
    original_price = ROUND((original_price * 1.08)::DECIMAL(10,2), 2),
    currency = 'USD',
    updated_at = NOW()
WHERE currency IS NULL OR currency = 'EUR';

-- Étape 3: Afficher un résumé des modifications
SELECT 
    'Conversion terminée' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN currency = 'USD' THEN 1 END) as usd_products,
    COUNT(CASE WHEN currency = 'EUR' THEN 1 END) as eur_products,
    COUNT(CASE WHEN currency = 'CDF' THEN 1 END) as cdf_products
FROM products;

-- Étape 4: Afficher quelques exemples de produits convertis
SELECT 
    id,
    name,
    price,
    original_price,
    currency,
    updated_at
FROM products 
ORDER BY updated_at DESC 
LIMIT 5;

-- Message de confirmation
SELECT 'Tous les triggers corrigés et produits convertis en USD!' as message;
