-- =====================================================
-- 🚀 INSTALLATION COMPLÈTE DU SYSTÈME E-COMMERCE
-- =====================================================

-- Ce script installe le système de portefeuille ET la gestion automatique des quantités
-- Il peut être exécuté plusieurs fois sans erreur

-- =====================================================
-- PARTIE 1: SYSTÈME DE PORTEFEUILLE
-- =====================================================

-- Étape 1: Vérifier et ajouter la colonne role à users
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'role') THEN
        ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'driver', 'admin'));
        RAISE NOTICE 'Colonne role ajoutée à la table users';
    ELSE
        RAISE NOTICE 'Colonne role existe déjà dans la table users';
    END IF;
END $$;

-- Étape 2: Vérifier et ajouter les colonnes manquantes à products
DO $$ 
BEGIN
    -- Ajouter la colonne seller_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'seller_id') THEN
        ALTER TABLE products ADD COLUMN seller_id UUID REFERENCES auth.users(id);
        CREATE INDEX IF NOT EXISTS idx_products_seller_id ON products(seller_id);
        COMMENT ON COLUMN products.seller_id IS 'ID de l''utilisateur qui vend ce produit';
        RAISE NOTICE 'Colonne seller_id ajoutée à la table products';
    ELSE
        RAISE NOTICE 'Colonne seller_id existe déjà dans la table products';
    END IF;
    
    -- Ajouter la colonne quantity
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'quantity') THEN
        ALTER TABLE products ADD COLUMN quantity INTEGER DEFAULT 0 NOT NULL;
        RAISE NOTICE 'Colonne quantity ajoutée à la table products';
    ELSE
        RAISE NOTICE 'Colonne quantity existe déjà dans la table products';
    END IF;
    
    -- Ajouter la colonne is_available
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'is_available') THEN
        ALTER TABLE products ADD COLUMN is_available BOOLEAN DEFAULT true NOT NULL;
        RAISE NOTICE 'Colonne is_available ajoutée à la table products';
    ELSE
        RAISE NOTICE 'Colonne is_available existe déjà dans la table products';
    END IF;
    
    -- Ajouter la colonne updated_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'updated_at') THEN
        ALTER TABLE products ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL;
        RAISE NOTICE 'Colonne updated_at ajoutée à la table products';
    ELSE
        RAISE NOTICE 'Colonne updated_at existe déjà dans la table products';
    END IF;
END $$;

-- Étape 2.1: Mettre à jour les produits existants
UPDATE products 
SET is_available = true, 
    quantity = COALESCE(quantity, 10)  -- Valeur par défaut de 10 si quantity est NULL
WHERE is_available IS NULL OR quantity IS NULL;

-- Étape 2.2: Ajouter des contraintes pour assurer la cohérence
DO $$ 
BEGIN
    -- Ajouter une contrainte pour que quantity soit >= 0
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'products_quantity_positive'
    ) THEN
        ALTER TABLE products ADD CONSTRAINT products_quantity_positive CHECK (quantity >= 0);
        RAISE NOTICE 'Contrainte products_quantity_positive ajoutée';
    ELSE
        RAISE NOTICE 'Contrainte products_quantity_positive existe déjà';
    END IF;
END $$;

-- Étape 3: Créer la table wallets si elle n'existe pas
CREATE TABLE IF NOT EXISTS wallets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    balance DECIMAL(10,2) DEFAULT 0.00 NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD' NOT NULL CHECK (currency IN ('USD', 'CDF')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(user_id)
);

-- Étape 4: Créer la table wallet_transactions si elle n'existe pas
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('credit', 'debit', 'withdrawal', 'refund')),
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    reference VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Étape 5: Créer les index pour le portefeuille
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_type ON wallet_transactions(type);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_status ON wallet_transactions(status);

-- Étape 6: Créer la fonction de mise à jour automatique
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Étape 7: Créer le trigger de mise à jour (seulement s'il n'existe pas)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'update_wallets_updated_at' 
        AND event_object_table = 'wallets'
    ) THEN
        CREATE TRIGGER update_wallets_updated_at 
            BEFORE UPDATE ON wallets 
            FOR EACH ROW 
            EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Trigger update_wallets_updated_at créé';
    ELSE
        RAISE NOTICE 'Trigger update_wallets_updated_at existe déjà';
    END IF;
END $$;

-- Étape 8: Activer RLS pour le portefeuille
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;

-- Étape 9: Créer les politiques RLS pour wallets
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'wallets' AND policyname = 'Users can view their own wallet') THEN
        CREATE POLICY "Users can view their own wallet" ON wallets FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'wallets' AND policyname = 'Users can update their own wallet') THEN
        CREATE POLICY "Users can update their own wallet" ON wallets FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'wallets' AND policyname = 'Users can insert their own wallet') THEN
        CREATE POLICY "Users can insert their own wallet" ON wallets FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- Étape 10: Créer les politiques RLS pour wallet_transactions
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'wallet_transactions' AND policyname = 'Users can view their own wallet transactions') THEN
        CREATE POLICY "Users can view their own wallet transactions" ON wallet_transactions
            FOR SELECT USING (wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid()));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'wallet_transactions' AND policyname = 'Users can insert their own wallet transactions') THEN
        CREATE POLICY "Users can insert their own wallet transactions" ON wallet_transactions
            FOR INSERT WITH CHECK (wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid()));
    END IF;
END $$;

-- Étape 11: Créer la fonction pour créer automatiquement un portefeuille
CREATE OR REPLACE FUNCTION create_wallet_for_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO wallets (user_id, balance, currency)
    VALUES (NEW.id, 0.00, 'USD')
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Étape 12: Créer le trigger pour créer automatiquement un portefeuille
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'create_wallet_for_user_trigger' 
        AND event_object_table = 'users'
    ) THEN
        CREATE TRIGGER create_wallet_for_user_trigger
            AFTER INSERT ON users
            FOR EACH ROW
            EXECUTE FUNCTION create_wallet_for_user();
        RAISE NOTICE 'Trigger create_wallet_for_user_trigger créé';
    ELSE
        RAISE NOTICE 'Trigger create_wallet_for_user_trigger existe déjà';
    END IF;
END $$;

-- Étape 13: Créer la fonction pour ajouter de l'argent au portefeuille
CREATE OR REPLACE FUNCTION add_money_to_user_wallet()
RETURNS TRIGGER AS $$
DECLARE
    seller_wallet_id UUID;
    commission_rate DECIMAL(5,4) := 0.90;
    seller_amount DECIMAL(10,2);
BEGIN
    IF NEW.status = 'delivered' AND (TG_OP = 'INSERT' OR OLD.status != 'delivered') THEN
        SELECT w.id INTO seller_wallet_id
        FROM wallets w
        JOIN products p ON p.seller_id = w.user_id
        WHERE p.id = NEW.product_id;
        
        IF seller_wallet_id IS NOT NULL THEN
            seller_amount := NEW.total_amount * commission_rate;
            
            UPDATE wallets 
            SET balance = balance + seller_amount,
                updated_at = NOW()
            WHERE id = seller_wallet_id;
            
            INSERT INTO wallet_transactions (
                wallet_id, type, amount, description, order_id, status
            ) VALUES (
                seller_wallet_id, 'credit', seller_amount, 
                'Vente de produit - Commande #' || NEW.id, NEW.id, 'completed'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Étape 14: Créer le trigger pour ajouter de l'argent au portefeuille
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'add_money_to_user_wallet_trigger' 
        AND event_object_table = 'orders'
    ) THEN
        CREATE TRIGGER add_money_to_user_wallet_trigger
            AFTER UPDATE ON orders
            FOR EACH ROW
            EXECUTE FUNCTION add_money_to_user_wallet();
        RAISE NOTICE 'Trigger add_money_to_user_wallet_trigger créé';
    ELSE
        RAISE NOTICE 'Trigger add_money_to_user_wallet_trigger existe déjà';
    END IF;
END $$;

-- =====================================================
-- PARTIE 2: GESTION AUTOMATIQUE DES QUANTITÉS
-- =====================================================

-- Étape 15: Créer une fonction pour décrémenter la quantité du produit
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

-- Étape 16: Créer le trigger pour décrémenter automatiquement la quantité
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

-- Étape 17: Créer une fonction pour gérer les annulations de commande
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

-- Étape 18: Créer le trigger pour restaurer la quantité lors des annulations
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

-- Étape 19: Créer une fonction pour vérifier la disponibilité des produits
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

-- Étape 20: Créer le trigger pour vérifier la disponibilité
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

-- Étape 21: Ajouter des index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_products_quantity ON products(quantity) WHERE quantity > 0;
CREATE INDEX IF NOT EXISTS idx_products_available ON products(is_available) WHERE is_available = true;

-- Étape 22: Ajouter les commentaires
COMMENT ON TABLE wallets IS 'Table des portefeuilles des utilisateurs';
COMMENT ON TABLE wallet_transactions IS 'Table des transactions de portefeuille';
COMMENT ON COLUMN wallets.balance IS 'Solde actuel du portefeuille';
COMMENT ON COLUMN wallets.currency IS 'Devise du portefeuille: USD (Dollar) ou CDF (Franc Congolais)';
COMMENT ON COLUMN wallet_transactions.type IS 'Type de transaction: credit, debit, withdrawal, refund';
COMMENT ON COLUMN wallet_transactions.status IS 'Statut de la transaction: pending, completed, failed, cancelled';
COMMENT ON FUNCTION update_product_quantity_on_sale() IS 'Décrémente automatiquement la quantité du produit lors d''une vente';
COMMENT ON FUNCTION restore_product_quantity_on_cancel() IS 'Restore la quantité du produit lors d''une annulation';
COMMENT ON FUNCTION check_product_availability() IS 'Vérifie la disponibilité du produit avant la commande';

-- Message de succès
SELECT '🎉 Système complet installé avec succès !' as message;
