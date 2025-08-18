-- Script corrigé pour gérer la contrainte de clé étrangère avec auth.users
-- À exécuter dans l'éditeur SQL de Supabase

-- ÉTAPE 1: Vérifier l'état actuel
SELECT 'ÉTAPE 1: État actuel' as step;
SELECT 
    COUNT(*) as total_chats,
    COUNT(CASE WHEN customer_id = 'default_seller' THEN 1 END) as default_seller_customer,
    COUNT(CASE WHEN seller_id = 'default_seller' THEN 1 END) as default_seller_seller,
    COUNT(CASE WHEN customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as valid_customer_ids,
    COUNT(CASE WHEN seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as valid_seller_ids
FROM chats;

-- ÉTAPE 2: Vérifier quels IDs existent dans auth.users
SELECT 'ÉTAPE 2: Vérification des IDs dans auth.users' as step;
SELECT 
    'customer_id' as column_name,
    customer_id,
    CASE 
        WHEN customer_id IN (SELECT id::text FROM auth.users) THEN 'EXISTE dans auth.users'
        ELSE 'N''EXISTE PAS dans auth.users'
    END as auth_status
FROM chats
WHERE customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
UNION ALL
SELECT 
    'seller_id' as column_name,
    seller_id,
    CASE 
        WHEN seller_id IN (SELECT id::text FROM auth.users) THEN 'EXISTE dans auth.users'
        ELSE 'N''EXISTE PAS dans auth.users'
    END as auth_status
FROM chats
WHERE seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- ÉTAPE 3: Remplacer 'default_seller' par des UUIDs existants dans auth.users
SELECT 'ÉTAPE 3: Remplacement des default_seller' as step;

-- Remplacer seller_id 'default_seller' par un ID existant dans auth.users
UPDATE chats 
SET seller_id = (SELECT id::text FROM auth.users LIMIT 1)
WHERE seller_id = 'default_seller'
  AND EXISTS (SELECT 1 FROM auth.users LIMIT 1);

-- Remplacer customer_id 'default_seller' par un ID existant dans auth.users
UPDATE chats 
SET customer_id = (SELECT id::text FROM auth.users LIMIT 1)
WHERE customer_id = 'default_seller'
  AND EXISTS (SELECT 1 FROM auth.users LIMIT 1);

-- ÉTAPE 4: Créer les utilisateurs manquants (seulement pour les IDs qui existent dans auth.users)
SELECT 'ÉTAPE 4: Création des utilisateurs' as step;

-- Créer les utilisateurs clients (seulement s'ils existent dans auth.users)
INSERT INTO users (id, email, first_name, last_name, created_at)
SELECT DISTINCT
    customer_id::uuid,
    COALESCE(au.email, 'user_' || customer_id || '@example.com'),
    COALESCE(customer_name, 'Utilisateur'),
    'Client',
    NOW()
FROM chats c
LEFT JOIN auth.users au ON c.customer_id = au.id::text
WHERE customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  AND customer_id::uuid IN (SELECT id FROM auth.users)
  AND customer_id::uuid NOT IN (SELECT id FROM users)
ON CONFLICT (id) DO NOTHING;

-- Créer les utilisateurs vendeurs (seulement s'ils existent dans auth.users)
INSERT INTO users (id, email, first_name, last_name, created_at)
SELECT DISTINCT
    seller_id::uuid,
    COALESCE(au.email, 'seller_' || seller_id || '@example.com'),
    COALESCE(seller_name, 'Vendeur'),
    'Vendeur',
    NOW()
FROM chats c
LEFT JOIN auth.users au ON c.seller_id = au.id::text
WHERE seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  AND seller_id::uuid IN (SELECT id FROM auth.users)
  AND seller_id::uuid NOT IN (SELECT id FROM users)
ON CONFLICT (id) DO NOTHING;

-- ÉTAPE 5: Vérifier le résultat final
SELECT 'ÉTAPE 5: Résultat final' as step;
SELECT 
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM chats) as total_chats,
    (SELECT COUNT(DISTINCT customer_id) FROM chats) as unique_customers,
    (SELECT COUNT(DISTINCT seller_id) FROM chats) as unique_sellers,
    (SELECT COUNT(*) FROM auth.users) as total_auth_users;

-- ÉTAPE 6: Afficher les chats avec leurs statuts
SELECT 'ÉTAPE 6: Statut des chats' as step;
SELECT 
    c.id as chat_id,
    c.customer_id,
    c.customer_name,
    CASE 
        WHEN u_customer.id IS NOT NULL THEN 'Utilisateur créé'
        WHEN c.customer_id IN (SELECT id::text FROM auth.users) THEN 'Existe dans auth.users mais pas dans users'
        ELSE 'ID invalide ou inexistant'
    END as customer_status,
    c.seller_id,
    c.seller_name,
    CASE 
        WHEN u_seller.id IS NOT NULL THEN 'Utilisateur créé'
        WHEN c.seller_id IN (SELECT id::text FROM auth.users) THEN 'Existe dans auth.users mais pas dans users'
        ELSE 'ID invalide ou inexistant'
    END as seller_status
FROM chats c
LEFT JOIN users u_customer ON c.customer_id::uuid = u_customer.id
LEFT JOIN users u_seller ON c.seller_id::uuid = u_seller.id
ORDER BY c.created_at DESC
LIMIT 10;




