-- Script de test de connexion à Supabase
-- Ce script vérifie que la connexion fonctionne

-- 1. Test de connexion basique
SELECT '✅ Connexion réussie à Supabase!' as message;

-- 2. Vérifier les tables existantes
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 3. Vérifier le nombre de produits
SELECT 
    COUNT(*) as nombre_produits,
    COUNT(CASE WHEN is_available = true THEN 1 END) as produits_disponibles,
    COUNT(CASE WHEN stock_quantity > 0 THEN 1 END) as produits_en_stock
FROM products;

-- 4. Afficher quelques produits
SELECT 
    id,
    name,
    price,
    stock_quantity,
    is_available
FROM products 
ORDER BY created_at DESC
LIMIT 5;

-- 5. Vérifier les triggers existants
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;
