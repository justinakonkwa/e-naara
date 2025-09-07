-- =====================================================
-- 📦 GESTION AUTOMATIQUE DES QUANTITÉS DE PRODUITS
-- =====================================================

-- Ce script met à jour automatiquement la quantité des produits lors des ventes

-- Étape 1: Créer une fonction pour décrémenter la quantité du produit
CREATE OR REPLACE FUNCTION update_product_quantity_on_sale()
RETURNS TRIGGER AS $$
DECLARE
    current_quantity INTEGER;
    order_quantity INTEGER;
BEGIN
    -- Récupérer la quantité actuelle du produit
    SELECT quantity INTO current_quantity
    FROM products
    WHERE id = NEW.product_id;
    
    -- Récupérer la quantité commandée
    order_quantity := NEW.quantity;
    
    -- Vérifier si la quantité est suffisante
    IF current_quantity < order_quantity THEN
        RAISE EXCEPTION 'Quantité insuffisante pour le produit % (disponible: %, demandée: %)', 
            NEW.product_id, current_quantity, order_quantity;
    END IF;
    
    -- Décrémenter la quantité du produit
    UPDATE products 
    SET quantity = quantity - order_quantity,
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

-- Étape 2: Créer le trigger pour décrémenter automatiquement la quantité
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'update_product_quantity_trigger' 
        AND event_object_table = 'orders'
    ) THEN
        CREATE TRIGGER update_product_quantity_trigger
            BEFORE INSERT ON orders
            FOR EACH ROW
            EXECUTE FUNCTION update_product_quantity_on_sale();
        RAISE NOTICE 'Trigger update_product_quantity_trigger créé';
    ELSE
        RAISE NOTICE 'Trigger update_product_quantity_trigger existe déjà';
    END IF;
END $$;

-- Étape 3: Créer une fonction pour gérer les annulations de commande (remboursement de quantité)
CREATE OR REPLACE FUNCTION restore_product_quantity_on_cancel()
RETURNS TRIGGER AS $$
DECLARE
    order_quantity INTEGER;
BEGIN
    -- Si la commande est annulée ou remboursée
    IF NEW.status IN ('cancelled', 'refunded') AND OLD.status NOT IN ('cancelled', 'refunded') THEN
        -- Récupérer la quantité de la commande
        order_quantity := NEW.quantity;
        
        -- Restaurer la quantité du produit
        UPDATE products 
        SET quantity = quantity + order_quantity,
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

-- Étape 4: Créer le trigger pour restaurer la quantité lors des annulations
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'restore_product_quantity_trigger' 
        AND event_object_table = 'orders'
    ) THEN
        CREATE TRIGGER restore_product_quantity_trigger
            AFTER UPDATE ON orders
            FOR EACH ROW
            EXECUTE FUNCTION restore_product_quantity_on_cancel();
        RAISE NOTICE 'Trigger restore_product_quantity_trigger créé';
    ELSE
        RAISE NOTICE 'Trigger restore_product_quantity_trigger existe déjà';
    END IF;
END $$;

-- Étape 5: Créer une fonction pour vérifier la disponibilité des produits
CREATE OR REPLACE FUNCTION check_product_availability()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier si le produit est disponible
    IF NOT EXISTS (
        SELECT 1 FROM products 
        WHERE id = NEW.product_id 
        AND is_available = true 
        AND quantity > 0
    ) THEN
        RAISE EXCEPTION 'Le produit % n''est pas disponible', NEW.product_id;
    END IF;
    
    -- Vérifier si la quantité demandée est disponible
    IF EXISTS (
        SELECT 1 FROM products 
        WHERE id = NEW.product_id 
        AND quantity < NEW.quantity
    ) THEN
        RAISE EXCEPTION 'Quantité insuffisante pour le produit %', NEW.product_id;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Étape 6: Créer le trigger pour vérifier la disponibilité
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'check_product_availability_trigger' 
        AND event_object_table = 'orders'
    ) THEN
        CREATE TRIGGER check_product_availability_trigger
            BEFORE INSERT ON orders
            FOR EACH ROW
            EXECUTE FUNCTION check_product_availability();
        RAISE NOTICE 'Trigger check_product_availability_trigger créé';
    ELSE
        RAISE NOTICE 'Trigger check_product_availability_trigger existe déjà';
    END IF;
END $$;

-- Étape 7: Ajouter des index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_products_quantity ON products(quantity) WHERE quantity > 0;
CREATE INDEX IF NOT EXISTS idx_products_available ON products(is_available) WHERE is_available = true;

-- Étape 8: Ajouter des commentaires
COMMENT ON FUNCTION update_product_quantity_on_sale() IS 'Décrémente automatiquement la quantité du produit lors d''une vente';
COMMENT ON FUNCTION restore_product_quantity_on_cancel() IS 'Restore la quantité du produit lors d''une annulation';
COMMENT ON FUNCTION check_product_availability() IS 'Vérifie la disponibilité du produit avant la commande';

-- Message de succès
SELECT '🎉 Système de gestion des quantités installé avec succès !' as message;
