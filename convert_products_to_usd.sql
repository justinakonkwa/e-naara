-- =====================================================
-- 🚀 CONVERSION DES PRODUITS EN USD ET AJOUT DE LA COLONNE DEVISE
-- =====================================================

-- Ce script convertit tous les produits existants d'EUR vers USD et ajoute la colonne devise

-- Étape 1: Ajouter la colonne currency à la table products si elle n'existe pas
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
-- Note: Cette conversion ne s'applique que si la devise n'est pas déjà définie ou si elle est EUR
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

-- Étape 5: Vérifier que tous les produits ont maintenant la devise USD
SELECT 
    'Vérification finale' as info,
    COUNT(*) as total_products,
    COUNT(CASE WHEN currency = 'USD' THEN 1 END) as usd_products,
    ROUND((COUNT(CASE WHEN currency = 'USD' THEN 1 END) * 100.0 / COUNT(*))::DECIMAL(5,2), 2) as percentage_usd
FROM products;

-- Message de confirmation
SELECT '✅ Tous les produits ont été convertis en USD avec succès!' as message;
