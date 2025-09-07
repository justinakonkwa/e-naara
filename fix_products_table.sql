-- =====================================================
-- 🔧 CORRECTION DE LA TABLE PRODUCTS
-- =====================================================

-- Ce script ajoute les colonnes manquantes à la table products

-- Étape 1: Vérifier et ajouter la colonne quantity
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'quantity') THEN
        ALTER TABLE products ADD COLUMN quantity INTEGER DEFAULT 0 NOT NULL;
        RAISE NOTICE 'Colonne quantity ajoutée à la table products';
    ELSE
        RAISE NOTICE 'Colonne quantity existe déjà dans la table products';
    END IF;
END $$;

-- Étape 2: Vérifier et ajouter la colonne is_available
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'is_available') THEN
        ALTER TABLE products ADD COLUMN is_available BOOLEAN DEFAULT true NOT NULL;
        RAISE NOTICE 'Colonne is_available ajoutée à la table products';
    ELSE
        RAISE NOTICE 'Colonne is_available existe déjà dans la table products';
    END IF;
END $$;

-- Étape 3: Vérifier et ajouter la colonne updated_at
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'updated_at') THEN
        ALTER TABLE products ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL;
        RAISE NOTICE 'Colonne updated_at ajoutée à la table products';
    ELSE
        RAISE NOTICE 'Colonne updated_at existe déjà dans la table products';
    END IF;
END $$;

-- Étape 4: Vérifier et ajouter la colonne seller_id (si pas déjà fait)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'seller_id') THEN
        ALTER TABLE products ADD COLUMN seller_id UUID REFERENCES auth.users(id);
        CREATE INDEX IF NOT EXISTS idx_products_seller_id ON products(seller_id);
        COMMENT ON COLUMN products.seller_id IS 'ID de l''utilisateur qui vend ce produit';
        RAISE NOTICE 'Colonne seller_id ajoutée à la table products';
    ELSE
        RAISE NOTICE 'Colonne seller_id existe déjà dans la table products';
    END IF;
END $$;

-- Étape 5: Mettre à jour les produits existants pour qu'ils soient disponibles
UPDATE products 
SET is_available = true, 
    quantity = COALESCE(quantity, 10)  -- Valeur par défaut de 10 si quantity est NULL
WHERE is_available IS NULL OR quantity IS NULL;

-- Étape 6: Créer les index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_products_quantity ON products(quantity) WHERE quantity > 0;
CREATE INDEX IF NOT EXISTS idx_products_available ON products(is_available) WHERE is_available = true;

-- Étape 7: Ajouter des contraintes pour assurer la cohérence
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

-- Étape 8: Ajouter des commentaires
COMMENT ON COLUMN products.quantity IS 'Quantité disponible en stock';
COMMENT ON COLUMN products.is_available IS 'Indique si le produit est disponible à la vente';
COMMENT ON COLUMN products.updated_at IS 'Date de dernière modification';

-- Étape 9: Afficher la structure finale de la table
SELECT 'Structure de la table products:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
ORDER BY ordinal_position;

-- Message de succès
SELECT '🎉 Table products corrigée avec succès !' as message;
