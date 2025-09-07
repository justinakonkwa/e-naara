-- =====================================================
-- 🔍 VÉRIFICATION DE LA STRUCTURE DE LA TABLE ORDERS
-- =====================================================

-- Vérifier la structure actuelle de la table orders
SELECT 'Structure actuelle de la table orders:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Vérifier les contraintes de clés étrangères
SELECT 'Contraintes de clés étrangères:' as info;

SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'orders';

-- Vérifier les données existantes
SELECT 'Données existantes:' as info;

SELECT 
    COUNT(*) as total_commandes,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as en_attente,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmees,
    COUNT(CASE WHEN status = 'picked_up' THEN 1 END) as recuperees,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as livrees
FROM orders;

-- Vérifier un exemple de commande
SELECT 'Exemple de commande:' as info;

SELECT 
    id,
    user_id,
    product_id,
    quantity,
    total_amount,
    status,
    driver_id,
    created_at,
    updated_at
FROM orders 
LIMIT 1;

