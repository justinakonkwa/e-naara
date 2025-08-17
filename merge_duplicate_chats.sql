-- Script pour fusionner les chats en double en conservant tous les messages
-- À exécuter dans l'éditeur SQL de Supabase

-- Étape 1: Identifier les chats en double pour le produit "Amplificateur"
SELECT 
    product_id,
    customer_id,
    customer_name,
    seller_id,
    seller_name,
    COUNT(*) as chat_count,
    STRING_AGG(id::text, ', ') as chat_ids,
    MIN(created_at) as earliest_created,
    MAX(created_at) as latest_created
FROM chats
WHERE product_name = 'Amplificateur' 
    AND customer_name = 'test client client' 
    AND seller_name = 'Vendeur'
GROUP BY product_id, customer_id, customer_name, seller_id, seller_name
HAVING COUNT(*) > 1;

-- Étape 2: Choisir le chat principal (le plus ancien avec le plus de messages)
WITH chat_stats AS (
    SELECT 
        c.id,
        c.product_id,
        c.customer_id,
        c.customer_name,
        c.seller_id,
        c.seller_name,
        c.created_at,
        COUNT(cm.id) as message_count
    FROM chats c
    LEFT JOIN chat_messages cm ON c.id = cm.chat_id
    WHERE c.product_name = 'Amplificateur' 
        AND c.customer_name = 'test client client' 
        AND c.seller_name = 'Vendeur'
    GROUP BY c.id, c.product_id, c.customer_id, c.customer_name, c.seller_id, c.seller_name, c.created_at
)
SELECT 
    id as main_chat_id,
    product_id,
    customer_id,
    customer_name,
    seller_id,
    seller_name,
    created_at,
    message_count
FROM chat_stats
ORDER BY message_count DESC, created_at ASC
LIMIT 1;

-- Étape 3: Déplacer tous les messages vers le chat principal
-- Remplacer '1755356841902' par l'ID du chat principal trouvé ci-dessus
UPDATE chat_messages 
SET chat_id = '1755356841902'  -- Chat principal avec le plus de messages
WHERE chat_id IN ('1755356882251', '1755356868631')  -- Chats en double
    AND chat_id != '1755356841902';

-- Étape 4: Mettre à jour le timestamp du dernier message dans le chat principal
UPDATE chats 
SET last_message_at = (
    SELECT MAX(timestamp) 
    FROM chat_messages 
    WHERE chat_id = '1755356841902'
)
WHERE id = '1755356841902';

-- Étape 5: Supprimer les chats en double vides
DELETE FROM chats 
WHERE id IN ('1755356882251', '1755356868631')
    AND id != '1755356841902';

-- Étape 6: Vérifier le résultat
SELECT 
    c.id as chat_id,
    c.product_name,
    c.customer_name,
    c.seller_name,
    c.created_at,
    c.last_message_at,
    COUNT(cm.id) as message_count
FROM chats c
LEFT JOIN chat_messages cm ON c.id = cm.chat_id
WHERE c.product_name = 'Amplificateur' 
    AND c.customer_name = 'test client client' 
    AND c.seller_name = 'Vendeur'
GROUP BY c.id, c.product_name, c.customer_name, c.seller_name, c.created_at, c.last_message_at
ORDER BY c.created_at;

-- Étape 7: Vérifier tous les messages dans le chat principal
SELECT 
    id,
    chat_id,
    sender_id,
    sender_name,
    sender_type,
    message,
    timestamp,
    is_read
FROM chat_messages
WHERE chat_id = '1755356841902'
ORDER BY timestamp ASC;
