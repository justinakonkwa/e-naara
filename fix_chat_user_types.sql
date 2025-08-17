-- Script pour corriger les problèmes de types entre les tables chats et users
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure actuelle des tables
SELECT 
    'chats' as table_name,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'chats' AND column_name IN ('customer_id', 'seller_id')
UNION ALL
SELECT 
    'users' as table_name,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'id';

-- 2. Vérifier les données problématiques dans chats
SELECT 
    'customer_id' as column_name,
    customer_id,
    CASE 
        WHEN customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
        THEN 'UUID valide'
        ELSE 'UUID invalide'
    END as status
FROM chats
WHERE customer_id IS NOT NULL
LIMIT 5
UNION ALL
SELECT 
    'seller_id' as column_name,
    seller_id,
    CASE 
        WHEN seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
        THEN 'UUID valide'
        ELSE 'UUID invalide'
    END as status
FROM chats
WHERE seller_id IS NOT NULL
LIMIT 5;

-- 3. Option 1: Modifier la table users pour accepter TEXT (si les IDs dans chats sont corrects)
-- ALTER TABLE users ALTER COLUMN id TYPE TEXT;

-- 4. Option 2: Modifier la table chats pour utiliser UUID (recommandé)
-- D'abord, vérifier si tous les IDs sont des UUIDs valides
SELECT 
    COUNT(*) as total_chats,
    COUNT(CASE WHEN customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as valid_customer_ids,
    COUNT(CASE WHEN seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as valid_seller_ids
FROM chats;

-- 5. Si tous les IDs sont valides, modifier la table chats
-- ALTER TABLE chats ALTER COLUMN customer_id TYPE UUID USING customer_id::uuid;
-- ALTER TABLE chats ALTER COLUMN seller_id TYPE UUID USING seller_id::uuid;

-- 6. Créer des utilisateurs pour les IDs manquants (avec gestion d'erreur)
DO $$
DECLARE
    chat_record RECORD;
    user_count INTEGER;
BEGIN
    -- Pour les clients
    FOR chat_record IN SELECT DISTINCT customer_id, customer_name FROM chats 
                      WHERE customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    LOOP
        -- Vérifier si l'utilisateur existe déjà
        SELECT COUNT(*) INTO user_count FROM users WHERE id = chat_record.customer_id::uuid;
        
        IF user_count = 0 THEN
            BEGIN
                INSERT INTO users (id, email, first_name, last_name, created_at)
                VALUES (
                    chat_record.customer_id::uuid,
                    'user_' || chat_record.customer_id || '@example.com',
                    COALESCE(chat_record.customer_name, 'Utilisateur'),
                    'Client',
                    NOW()
                );
                RAISE NOTICE 'Utilisateur client créé: %', chat_record.customer_id;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Erreur lors de la création de l''utilisateur client %: %', chat_record.customer_id, SQLERRM;
            END;
        END IF;
    END LOOP;
    
    -- Pour les vendeurs
    FOR chat_record IN SELECT DISTINCT seller_id, seller_name FROM chats 
                      WHERE seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    LOOP
        -- Vérifier si l'utilisateur existe déjà
        SELECT COUNT(*) INTO user_count FROM users WHERE id = chat_record.seller_id::uuid;
        
        IF user_count = 0 THEN
            BEGIN
                INSERT INTO users (id, email, first_name, last_name, created_at)
                VALUES (
                    chat_record.seller_id::uuid,
                    'seller_' || chat_record.seller_id || '@example.com',
                    COALESCE(chat_record.seller_name, 'Vendeur'),
                    'Vendeur',
                    NOW()
                );
                RAISE NOTICE 'Utilisateur vendeur créé: %', chat_record.seller_id;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Erreur lors de la création de l''utilisateur vendeur %: %', chat_record.seller_id, SQLERRM;
            END;
        END IF;
    END LOOP;
END $$;

-- 7. Vérifier le résultat
SELECT 
    'Résumé après correction' as message,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM chats) as total_chats,
    (SELECT COUNT(DISTINCT customer_id) FROM chats) as unique_customers,
    (SELECT COUNT(DISTINCT seller_id) FROM chats) as unique_sellers;


