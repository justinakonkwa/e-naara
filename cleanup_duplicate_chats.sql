-- Script pour nettoyer les chats en double
-- À exécuter dans l'éditeur SQL de Supabase

-- Voir tous les chats avant nettoyage
SELECT 
    id,
    customer_id,
    customer_name,
    seller_id,
    seller_name,
    product_id,
    product_name,
    created_at,
    last_message_at
FROM chats
ORDER BY product_id, created_at;

-- Identifier les chats en double (même produit, même client, même vendeur)
WITH duplicate_chats AS (
    SELECT 
        product_id,
        customer_id,
        seller_id,
        COUNT(*) as chat_count,
        MIN(created_at) as earliest_created,
        MAX(created_at) as latest_created
    FROM chats
    GROUP BY product_id, customer_id, seller_id
    HAVING COUNT(*) > 1
)
SELECT 
    dc.*,
    c.id as chat_id,
    c.created_at,
    c.last_message_at
FROM duplicate_chats dc
JOIN chats c ON 
    c.product_id = dc.product_id 
    AND c.customer_id = dc.customer_id 
    AND c.seller_id = dc.seller_id
ORDER BY dc.product_id, dc.customer_id, dc.seller_id, c.created_at;

-- Supprimer les chats en double en gardant le plus ancien (qui a probablement des messages)
-- ATTENTION: Exécuter seulement après avoir vérifié les données ci-dessus
/*
DELETE FROM chats 
WHERE id IN (
    SELECT c.id
    FROM chats c
    JOIN (
        SELECT 
            product_id,
            customer_id,
            seller_id,
            MIN(created_at) as earliest_created
        FROM chats
        GROUP BY product_id, customer_id, seller_id
        HAVING COUNT(*) > 1
    ) duplicates ON 
        c.product_id = duplicates.product_id 
        AND c.customer_id = duplicates.customer_id 
        AND c.seller_id = duplicates.seller_id
        AND c.created_at > duplicates.earliest_created
);
*/

-- Vérifier les messages orphelins (messages sans chat)
SELECT 
    cm.id,
    cm.chat_id,
    cm.sender_id,
    cm.message,
    cm.timestamp
FROM chat_messages cm
LEFT JOIN chats c ON cm.chat_id = c.id
WHERE c.id IS NULL;

-- Supprimer les messages orphelins (optionnel)
-- DELETE FROM chat_messages WHERE chat_id NOT IN (SELECT id FROM chats);

-- Vérifier le résultat après nettoyage
SELECT 
    id,
    customer_id,
    customer_name,
    seller_id,
    seller_name,
    product_id,
    product_name,
    created_at,
    last_message_at
FROM chats
ORDER BY product_id, created_at;

-- Compter les messages par chat après nettoyage
SELECT 
    c.id as chat_id,
    c.product_name,
    c.customer_name,
    c.seller_name,
    COUNT(cm.id) as message_count
FROM chats c
LEFT JOIN chat_messages cm ON c.id = cm.chat_id
GROUP BY c.id, c.product_name, c.customer_name, c.seller_name
ORDER BY message_count DESC;
