-- Script de debug pour les problèmes de noms d'utilisateurs dans les chats
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure de la table users
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- 2. Vérifier les données existantes dans la table users
SELECT 
    id,
    email,
    first_name,
    last_name,
    created_at
FROM users
LIMIT 10;

-- 3. Vérifier les chats existants et leurs IDs d'utilisateurs
SELECT 
    id as chat_id,
    customer_id,
    customer_name,
    seller_id,
    seller_name,
    product_name,
    created_at
FROM chats
ORDER BY created_at DESC
LIMIT 10;

-- 4. Vérifier quels utilisateurs des chats existent dans la table users (avec cast UUID)
SELECT 
    c.id as chat_id,
    c.customer_id,
    c.customer_name,
    CASE 
        WHEN u_customer.id IS NOT NULL THEN 'EXISTE'
        ELSE 'MANQUANT'
    END as customer_exists,
    c.seller_id,
    c.seller_name,
    CASE 
        WHEN u_seller.id IS NOT NULL THEN 'EXISTE'
        ELSE 'MANQUANT'
    END as seller_exists
FROM chats c
LEFT JOIN users u_customer ON c.customer_id::uuid = u_customer.id
LEFT JOIN users u_seller ON c.seller_id::uuid = u_seller.id
ORDER BY c.created_at DESC
LIMIT 10;

-- 5. Créer des utilisateurs manquants pour les chats existants (avec cast UUID)
-- (Si les utilisateurs n'existent pas dans auth.users, cette requête échouera)
INSERT INTO users (id, email, first_name, last_name, created_at)
SELECT DISTINCT
    c.customer_id::uuid,
    'user_' || c.customer_id || '@example.com' as email,
    COALESCE(c.customer_name, 'Utilisateur') as first_name,
    'Client' as last_name,
    NOW() as created_at
FROM chats c
WHERE c.customer_id::uuid NOT IN (SELECT id FROM users)
  AND c.customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
ON CONFLICT (id) DO NOTHING;

INSERT INTO users (id, email, first_name, last_name, created_at)
SELECT DISTINCT
    c.seller_id::uuid,
    'seller_' || c.seller_id || '@example.com' as email,
    COALESCE(c.seller_name, 'Vendeur') as first_name,
    'Vendeur' as last_name,
    NOW() as created_at
FROM chats c
WHERE c.seller_id::uuid NOT IN (SELECT id FROM users)
  AND c.seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
ON CONFLICT (id) DO NOTHING;

-- 6. Vérifier les politiques RLS sur la table users
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

-- 7. Vérifier que RLS est activé
SELECT 
    schemaname, 
    tablename, 
    rowsecurity 
FROM pg_tables 
WHERE tablename = 'users';

-- 8. Afficher un résumé
SELECT 
    'Résumé du debug des utilisateurs de chat' as message,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM chats) as total_chats,
    (SELECT COUNT(DISTINCT customer_id) FROM chats) as unique_customers,
    (SELECT COUNT(DISTINCT seller_id) FROM chats) as unique_sellers;
