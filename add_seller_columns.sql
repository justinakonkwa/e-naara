-- Script pour ajouter les colonnes seller_id et seller_name à la table products
-- À exécuter dans l'éditeur SQL de Supabase

-- Ajouter les colonnes seller_id et seller_name à la table products
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS seller_id TEXT,
ADD COLUMN IF NOT EXISTS seller_name TEXT;

-- Ajouter des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_products_seller_id ON products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_seller_name ON products(seller_name);

-- Mettre à jour les produits existants avec des valeurs par défaut
UPDATE products 
SET 
    seller_id = 'default_seller',
    seller_name = 'Vendeur par défaut'
WHERE seller_id IS NULL OR seller_name IS NULL;

-- Rendre les colonnes NOT NULL après avoir mis à jour les données existantes
ALTER TABLE products 
ALTER COLUMN seller_id SET NOT NULL,
ALTER COLUMN seller_name SET NOT NULL;

-- Ajouter des valeurs par défaut pour les nouvelles colonnes
ALTER TABLE products 
ALTER COLUMN seller_id SET DEFAULT 'default_seller',
ALTER COLUMN seller_name SET DEFAULT 'Vendeur par défaut';

-- Commentaires pour documenter les nouvelles colonnes
COMMENT ON COLUMN products.seller_id IS 'ID de l''utilisateur vendeur du produit';
COMMENT ON COLUMN products.seller_name IS 'Nom du vendeur du produit';

-- Vérifier que les colonnes ont été ajoutées
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name IN ('seller_id', 'seller_name')
ORDER BY column_name;
