-- Script pour nettoyer les données invalides dans la table chats
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Identifier les données problématiques
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
WHERE seller_id IS NOT NULL;

-- 2. Compter les données problématiques
SELECT 
    COUNT(*) as total_chats,
    COUNT(CASE WHEN customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as valid_customer_ids,
    COUNT(CASE WHEN seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as valid_seller_ids,
    COUNT(CASE WHEN customer_id NOT LIKE 'default_seller' AND customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as clean_customer_ids,
    COUNT(CASE WHEN seller_id NOT LIKE 'default_seller' AND seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as clean_seller_ids
FROM chats;

-- 3. Supprimer les chats avec des IDs invalides (optionnel - à utiliser avec précaution)
-- DELETE FROM chats 
-- WHERE customer_id = 'default_seller' 
--    OR seller_id = 'default_seller'
--    OR customer_id NOT LIKE '%-%-%-%-%'
--    OR seller_id NOT LIKE '%-%-%-%-%';

-- 4. Alternative : Mettre à jour les IDs invalides avec des UUIDs générés
-- Générer un UUID pour remplacer 'default_seller'
UPDATE chats 
SET seller_id = gen_random_uuid()::text
WHERE seller_id = 'default_seller';

UPDATE chats 
SET customer_id = gen_random_uuid()::text
WHERE customer_id = 'default_seller';

-- 5. Vérifier que tous les IDs sont maintenant des UUIDs valides
SELECT 
    COUNT(*) as total_chats,
    COUNT(CASE WHEN customer_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as valid_customer_ids,
    COUNT(CASE WHEN seller_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as valid_seller_ids
FROM chats;

-- 6. Créer des utilisateurs pour tous les IDs valides
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

-- 7. Vérifier le résultat final
SELECT 
    'Résumé après nettoyage' as message,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM chats) as total_chats,
    (SELECT COUNT(DISTINCT customer_id) FROM chats) as unique_customers,
    (SELECT COUNT(DISTINCT seller_id) FROM chats) as unique_sellers;




