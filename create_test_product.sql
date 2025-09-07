-- =====================================================
-- 🧪 CRÉATION DU PRODUIT DE TEST
-- =====================================================

-- Supprimer l'ancien produit de test s'il existe
DELETE FROM products WHERE id = 'test-product-123';

-- Insérer un produit de test
INSERT INTO products (
    id,
    name,
    description,
    price,
    category,
    image_url,
    stock_quantity,
    seller_id,
    created_at,
    updated_at,
    is_available
) VALUES (
    'test-product-123',
    'Produit de Test',
    'Produit de test pour les commandes de développement',
    29.99,
    'test',
    'https://via.placeholder.com/300x300?text=Test+Product',
    100,
    '1e87d033-767a-46e5-9764-df8f5c2a08ea',
    NOW(),
    NOW(),
    true
);

-- Vérifier l'insertion
SELECT 
    '✅ Produit de test créé:' as message,
    id,
    name,
    price,
    stock_quantity
FROM products 
WHERE id = 'test-product-123';

-- Afficher le message de succès
SELECT '✅ Produit de test test-product-123 créé avec succès !' as result;

