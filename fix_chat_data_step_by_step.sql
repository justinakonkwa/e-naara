-- Script étape par étape pour corriger les données de chat
-- Exécuter chaque section séparément

-- ÉTAPE 1: Vérifier l'état actuel
SELECT 'ÉTAPE 1: État actuel' as step;
SELECT 
    COUNT(*) as total_chats,
    COUNT(CASE WHEN customer_id = 'default_seller' THEN 1 END) as default_seller_customer,
    COUNT(CASE WHEN seller_id = 'default_seller' THEN 1 END) as default_seller_seller,
    COUNT(CASE WHEN customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as valid_customer_ids,
    COUNT(CASE WHEN seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as valid_seller_ids
FROM chats;

-- ÉTAPE 2: Remplacer 'default_seller' par des UUIDs valides
SELECT 'ÉTAPE 2: Remplacement des default_seller' as step;
UPDATE chats 
SET seller_id = gen_random_uuid()::text
WHERE seller_id = 'default_seller';

UPDATE chats 
SET customer_id = gen_random_uuid()::text
WHERE customer_id = 'default_seller';

-- ÉTAPE 3: Vérifier que tous les IDs sont maintenant valides
SELECT 'ÉTAPE 3: Vérification après correction' as step;
SELECT 
    COUNT(*) as total_chats,
    COUNT(CASE WHEN customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as valid_customer_ids,
    COUNT(CASE WHEN seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as valid_seller_ids
FROM chats;

-- ÉTAPE 4: Créer les utilisateurs manquants
SELECT 'ÉTAPE 4: Création des utilisateurs' as step;

-- Créer les utilisateurs clients
INSERT INTO users (id, email, first_name, last_name, created_at)
SELECT DISTINCT
    customer_id::uuid,
    'user_' || customer_id || '@example.com',
    COALESCE(customer_name, 'Utilisateur'),
    'Client',
    NOW()
FROM chats
WHERE customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  AND customer_id::uuid NOT IN (SELECT id FROM users)
ON CONFLICT (id) DO NOTHING;

-- Créer les utilisateurs vendeurs
INSERT INTO users (id, email, first_name, last_name, created_at)
SELECT DISTINCT
    seller_id::uuid,
    'seller_' || seller_id || '@example.com',
    COALESCE(seller_name, 'Vendeur'),
    'Vendeur',
    NOW()
FROM chats
WHERE seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  AND seller_id::uuid NOT IN (SELECT id FROM users)
ON CONFLICT (id) DO NOTHING;

-- ÉTAPE 5: Vérifier le résultat final
SELECT 'ÉTAPE 5: Résultat final' as step;
SELECT 
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM chats) as total_chats,
    (SELECT COUNT(DISTINCT customer_id) FROM chats) as unique_customers,
    (SELECT COUNT(DISTINCT seller_id) FROM chats) as unique_sellers;




