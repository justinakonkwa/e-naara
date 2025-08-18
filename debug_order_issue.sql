-- =====================================================
-- 🔍 SCRIPT DE DEBUG POUR LE PROBLÈME DE COMMANDE MANQUANTE
-- =====================================================

-- 1. Vérifier la structure de la table orders
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- 2. Lister toutes les commandes existantes
SELECT 
    id,
    user_id,
    total_amount,
    shipping_address,
    status,
    created_at,
    updated_at,
    driver_id,
    assigned_at,
    picked_up_at,
    delivered_at,
    shipping_latitude,
    shipping_longitude
FROM orders 
ORDER BY created_at DESC 
LIMIT 10;

-- 3. Vérifier les politiques RLS sur la table orders
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'orders';

-- 4. Vérifier les permissions de l'utilisateur actuel
SELECT 
    grantee,
    table_name,
    privilege_type
FROM information_schema.table_privileges 
WHERE table_name = 'orders';

-- 5. Créer une commande de test si aucune n'existe
INSERT INTO orders (
    id,
    user_id,
    total_amount,
    shipping_address,
    payment_method,
    status,
    created_at,
    updated_at,
    shipping_latitude,
    shipping_longitude
) 
SELECT 
    '614ac82f-d4d1-470b-b1c8-52151570bddd'::uuid,
    auth.uid(),
    29.99,
    'UPN, Kinshasa, RDC',
    'card',
    'pending',
    NOW(),
    NOW(),
    -4.441,
    15.266
WHERE NOT EXISTS (
    SELECT 1 FROM orders WHERE id = '614ac82f-d4d1-470b-b1c8-52151570bddd'::uuid
);

-- 6. Vérifier que la commande de test a été créée
SELECT 
    id,
    user_id,
    total_amount,
    shipping_address,
    status,
    created_at,
    shipping_latitude,
    shipping_longitude
FROM orders 
WHERE id = '614ac82f-d4d1-470b-b1c8-52151570bddd'::uuid;

-- 7. Vérifier les utilisateurs existants
SELECT 
    id,
    email,
    created_at,
    role
FROM users 
ORDER BY created_at DESC 
LIMIT 5;

-- 8. Tester une requête simple pour vérifier l'accès
SELECT COUNT(*) as total_orders FROM orders;

-- 9. Vérifier les logs d'erreur récents (si disponible)
-- Note: Cette requête dépend de la configuration de logging de Supabase
SELECT 
    log_time,
    user_name,
    database_name,
    session_id,
    command_tag,
    message
FROM pg_stat_activity 
WHERE state = 'active' 
AND query LIKE '%orders%'
ORDER BY log_time DESC 
LIMIT 10;

