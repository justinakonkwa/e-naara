-- =====================================================
-- 🔍 VÉRIFICATION DE LA STRUCTURE DE LA BASE DE DONNÉES
-- =====================================================

-- Vérifier la structure de la table users
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- Vérifier la structure de la table orders
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Vérifier les contraintes sur la table users
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'users';

-- Vérifier les contraintes sur la table orders
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'orders';

-- Vérifier les index sur la table users
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'users';

-- Vérifier les index sur la table orders
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'orders';

-- Vérifier les politiques RLS sur la table users
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- Vérifier les politiques RLS sur la table orders
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- Vérifier les commentaires sur les colonnes
SELECT 
    table_name,
    column_name,
    col_description(
        (table_name)::regclass::oid, 
        ordinal_position
    ) as comment
FROM information_schema.columns 
WHERE table_name IN ('users', 'orders')
    AND col_description(
        (table_name)::regclass::oid, 
        ordinal_position
    ) IS NOT NULL
ORDER BY table_name, ordinal_position;

-- Vérifier les données existantes (sans afficher les données sensibles)
SELECT 
    'users' as table_name,
    COUNT(*) as row_count,
    COUNT(CASE WHEN role IS NOT NULL THEN 1 END) as users_with_role,
    COUNT(CASE WHEN role = 'user' THEN 1 END) as user_role_count,
    COUNT(CASE WHEN role = 'driver' THEN 1 END) as driver_role_count,
    COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_role_count
FROM users
UNION ALL
SELECT 
    'orders' as table_name,
    COUNT(*) as row_count,
    COUNT(CASE WHEN driver_id IS NOT NULL THEN 1 END) as orders_with_driver,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_orders,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_orders,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_orders
FROM orders;

-- Vérifier les relations entre les tables
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name IN ('users', 'orders', 'cart_items', 'order_items', 'reviews', 'wishlist');
