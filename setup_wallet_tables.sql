-- Création des tables pour le système de portefeuille

-- Vérifier que la colonne role existe dans la table users
DO $$ 
BEGIN
    -- Vérifier si la colonne role existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'role') THEN
        -- Ajouter la colonne role avec la contrainte (sans 'seller')
        ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'driver', 'admin'));
    END IF;
END $$;

-- Ajouter la colonne seller_id à la table products si elle n'existe pas déjà
DO $$ 
BEGIN
    -- Vérifier si la colonne seller_id existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'seller_id') THEN
        -- Ajouter la colonne seller_id
        ALTER TABLE products ADD COLUMN seller_id UUID REFERENCES auth.users(id);
        
        -- Créer un index pour améliorer les performances
        CREATE INDEX IF NOT EXISTS idx_products_seller_id ON products(seller_id);
        
        -- Ajouter un commentaire
        COMMENT ON COLUMN products.seller_id IS 'ID de l''utilisateur qui vend ce produit';
    END IF;
END $$;

-- Table des portefeuilles
CREATE TABLE IF NOT EXISTS wallets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    balance DECIMAL(10,2) DEFAULT 0.00 NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD' NOT NULL CHECK (currency IN ('USD', 'CDF')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(user_id)
);

-- Table des transactions de portefeuille
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

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_type ON wallet_transactions(type);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_status ON wallet_transactions(status);

-- Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger pour mettre à jour updated_at automatiquement (seulement s'il n'existe pas)
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
    END IF;
END $$;

-- Politiques RLS (Row Level Security)
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;

-- Politiques pour wallets (seulement si elles n'existent pas déjà)
DO $$ 
BEGIN
    -- Politique pour voir son propre portefeuille
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wallets' 
        AND policyname = 'Users can view their own wallet'
    ) THEN
        CREATE POLICY "Users can view their own wallet" ON wallets
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    -- Politique pour mettre à jour son propre portefeuille
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wallets' 
        AND policyname = 'Users can update their own wallet'
    ) THEN
        CREATE POLICY "Users can update their own wallet" ON wallets
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    
    -- Politique pour insérer son propre portefeuille
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wallets' 
        AND policyname = 'Users can insert their own wallet'
    ) THEN
        CREATE POLICY "Users can insert their own wallet" ON wallets
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- Politiques pour wallet_transactions (seulement si elles n'existent pas déjà)
DO $$ 
BEGIN
    -- Politique pour voir ses propres transactions
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wallet_transactions' 
        AND policyname = 'Users can view their own wallet transactions'
    ) THEN
        CREATE POLICY "Users can view their own wallet transactions" ON wallet_transactions
            FOR SELECT USING (
                wallet_id IN (
                    SELECT id FROM wallets WHERE user_id = auth.uid()
                )
            );
    END IF;
    
    -- Politique pour insérer ses propres transactions
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'wallet_transactions' 
        AND policyname = 'Users can insert their own wallet transactions'
    ) THEN
        CREATE POLICY "Users can insert their own wallet transactions" ON wallet_transactions
            FOR INSERT WITH CHECK (
                wallet_id IN (
                    SELECT id FROM wallets WHERE user_id = auth.uid()
                )
            );
    END IF;
END $$;

-- Fonction pour créer automatiquement un portefeuille lors de l'inscription d'un utilisateur
CREATE OR REPLACE FUNCTION create_wallet_for_user()
RETURNS TRIGGER AS $$
BEGIN
            -- Créer un portefeuille pour tous les utilisateurs
        INSERT INTO wallets (user_id, balance, currency)
        VALUES (NEW.id, 0.00, 'USD')
        ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger pour créer automatiquement un portefeuille pour tous les utilisateurs (seulement s'il n'existe pas)
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
    END IF;
END $$;

-- Fonction pour ajouter de l'argent au portefeuille lors d'une vente
CREATE OR REPLACE FUNCTION add_money_to_user_wallet()
RETURNS TRIGGER AS $$
DECLARE
    seller_wallet_id UUID;
    commission_rate DECIMAL(5,4) := 0.90; -- 90% pour l'utilisateur, 10% de commission
    seller_amount DECIMAL(10,2);
BEGIN
    -- Vérifier si la commande est complétée et si c'est un nouvel enregistrement
    IF NEW.status = 'delivered' AND (TG_OP = 'INSERT' OR OLD.status != 'delivered') THEN
        -- Récupérer l'ID du portefeuille de l'utilisateur qui vend
        SELECT w.id INTO seller_wallet_id
        FROM wallets w
        JOIN products p ON p.seller_id = w.user_id
        WHERE p.id = NEW.product_id;
        
        IF seller_wallet_id IS NOT NULL THEN
            -- Calculer le montant pour l'utilisateur (après commission)
            seller_amount := NEW.total_amount * commission_rate;
            
            -- Ajouter l'argent au portefeuille de l'utilisateur
            UPDATE wallets 
            SET balance = balance + seller_amount,
                updated_at = NOW()
            WHERE id = seller_wallet_id;
            
            -- Créer une transaction
            INSERT INTO wallet_transactions (
                wallet_id, 
                type, 
                amount, 
                description, 
                order_id, 
                status
            ) VALUES (
                seller_wallet_id,
                'credit',
                seller_amount,
                'Vente de produit - Commande #' || NEW.id,
                NEW.id,
                'completed'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger pour ajouter automatiquement de l'argent au portefeuille lors d'une vente (seulement s'il n'existe pas)
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
    END IF;
END $$;

-- Commentaires pour la documentation
COMMENT ON TABLE wallets IS 'Table des portefeuilles des utilisateurs';
COMMENT ON TABLE wallet_transactions IS 'Table des transactions de portefeuille';
COMMENT ON COLUMN wallets.balance IS 'Solde actuel du portefeuille';
COMMENT ON COLUMN wallets.currency IS 'Devise du portefeuille: USD (Dollar) ou CDF (Franc Congolais)';
COMMENT ON COLUMN wallet_transactions.type IS 'Type de transaction: credit, debit, withdrawal, refund';
COMMENT ON COLUMN wallet_transactions.status IS 'Statut de la transaction: pending, completed, failed, cancelled';
