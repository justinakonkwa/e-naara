-- =====================================================
-- 🔧 CORRECTION DE LA TABLE ORDERS
-- =====================================================

-- Ce script corrige la structure de la table orders pour le système e-commerce

-- Étape 1: Vérifier la structure actuelle de la table orders
SELECT 'Structure actuelle de la table orders:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Étape 2: Vérifier et ajouter la colonne product_id (TEXT pour correspondre à products.id)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'product_id') THEN
        ALTER TABLE orders ADD COLUMN product_id TEXT REFERENCES products(id);
        RAISE NOTICE 'Colonne product_id ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne product_id existe déjà dans la table orders';
    END IF;
END $$;

-- Étape 3: Vérifier et ajouter la colonne quantity
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'quantity') THEN
        ALTER TABLE orders ADD COLUMN quantity INTEGER DEFAULT 1 NOT NULL;
        RAISE NOTICE 'Colonne quantity ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne quantity existe déjà dans la table orders';
    END IF;
END $$;

-- Étape 4: Vérifier et ajouter la colonne total_amount
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'total_amount') THEN
        ALTER TABLE orders ADD COLUMN total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00;
        RAISE NOTICE 'Colonne total_amount ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne total_amount existe déjà dans la table orders';
    END IF;
END $$;

-- Étape 5: Vérifier et ajouter la colonne status
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'status') THEN
        ALTER TABLE orders ADD COLUMN status VARCHAR(20) DEFAULT 'pending' NOT NULL;
        RAISE NOTICE 'Colonne status ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne status existe déjà dans la table orders';
    END IF;
END $$;

-- Étape 6: Vérifier et ajouter la colonne user_id
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'user_id') THEN
        ALTER TABLE orders ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne user_id existe déjà dans la table orders';
    END IF;
END $$;

-- Étape 7: Vérifier et ajouter la colonne created_at
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'created_at') THEN
        ALTER TABLE orders ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL;
        RAISE NOTICE 'Colonne created_at ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne created_at existe déjà dans la table orders';
    END IF;
END $$;

-- Étape 8: Vérifier et ajouter la colonne updated_at
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'updated_at') THEN
        ALTER TABLE orders ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL;
        RAISE NOTICE 'Colonne updated_at ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne updated_at existe déjà dans la table orders';
    END IF;
END $$;

-- Étape 8.1: Vérifier et ajouter la colonne shipping_latitude
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_latitude') THEN
        ALTER TABLE orders ADD COLUMN shipping_latitude DOUBLE PRECISION;
        RAISE NOTICE 'Colonne shipping_latitude ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne shipping_latitude existe déjà dans la table orders';
    END IF;
END $$;

-- Étape 8.2: Vérifier et ajouter la colonne shipping_longitude
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_longitude') THEN
        ALTER TABLE orders ADD COLUMN shipping_longitude DOUBLE PRECISION;
        RAISE NOTICE 'Colonne shipping_longitude ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne shipping_longitude existe déjà dans la table orders';
    END IF;
END $$;

-- Étape 9: Nettoyer les données existantes avant d'ajouter les contraintes
SELECT 'Nettoyage des données existantes:' as info;

-- Vérifier les statuts existants
SELECT 'Statuts existants dans la table orders:' as info;
SELECT DISTINCT status FROM orders WHERE status IS NOT NULL;

-- Mettre à jour les statuts invalides vers 'pending'
UPDATE orders 
SET status = 'pending' 
WHERE status IS NULL OR status NOT IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled', 'refunded');

-- Mettre à jour les quantités invalides
UPDATE orders 
SET quantity = 1 
WHERE quantity IS NULL OR quantity <= 0;

-- Mettre à jour les montants invalides
UPDATE orders 
SET total_amount = 0.00 
WHERE total_amount IS NULL OR total_amount < 0;

-- Étape 10: Ajouter des contraintes pour assurer la cohérence
DO $$ 
BEGIN
    -- Contrainte pour quantity > 0
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'orders_quantity_positive'
    ) THEN
        ALTER TABLE orders ADD CONSTRAINT orders_quantity_positive CHECK (quantity > 0);
        RAISE NOTICE 'Contrainte orders_quantity_positive ajoutée';
    ELSE
        RAISE NOTICE 'Contrainte orders_quantity_positive existe déjà';
    END IF;
    
    -- Contrainte pour total_amount >= 0
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'orders_total_amount_positive'
    ) THEN
        ALTER TABLE orders ADD CONSTRAINT orders_total_amount_positive CHECK (total_amount >= 0);
        RAISE NOTICE 'Contrainte orders_total_amount_positive ajoutée';
    ELSE
        RAISE NOTICE 'Contrainte orders_total_amount_positive existe déjà';
    END IF;
    
    -- Contrainte pour status valide
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'orders_status_valid'
    ) THEN
        ALTER TABLE orders ADD CONSTRAINT orders_status_valid CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled', 'refunded'));
        RAISE NOTICE 'Contrainte orders_status_valid ajoutée';
    ELSE
        RAISE NOTICE 'Contrainte orders_status_valid existe déjà';
    END IF;
END $$;

-- Étape 10: Créer des index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_product_id ON orders(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- Étape 11: Ajouter des commentaires
COMMENT ON TABLE orders IS 'Table des commandes des utilisateurs';
COMMENT ON COLUMN orders.product_id IS 'ID du produit commandé';
COMMENT ON COLUMN orders.quantity IS 'Quantité commandée';
COMMENT ON COLUMN orders.total_amount IS 'Montant total de la commande';
COMMENT ON COLUMN orders.status IS 'Statut de la commande: pending, confirmed, shipped, delivered, cancelled, refunded';
COMMENT ON COLUMN orders.user_id IS 'ID de l''utilisateur qui a passé la commande';
COMMENT ON COLUMN orders.created_at IS 'Date de création de la commande';
COMMENT ON COLUMN orders.updated_at IS 'Date de dernière modification de la commande';

-- Étape 12: Afficher la structure finale
SELECT 'Structure finale de la table orders:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Étape 13: Vérifier les contraintes
SELECT 'Contraintes de la table orders:' as info;

SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_name LIKE 'orders_%'
ORDER BY constraint_name;

-- Étape 14: Statistiques finales
SELECT 'Statistiques de la table orders:' as info;

SELECT 
    COUNT(*) as total_commandes,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as commandes_en_attente,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as commandes_livrees,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as commandes_annulees,
    AVG(total_amount) as montant_moyen
FROM orders;

-- Message de succès
SELECT '🎉 Table orders corrigée avec succès !' as message;
