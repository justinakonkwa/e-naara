-- Script pour diagnostiquer les problèmes de chats
-- À exécuter dans l'éditeur SQL de Supabase

-- Vérifier tous les chats
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
ORDER BY created_at DESC;

-- Vérifier tous les messages
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
ORDER BY timestamp DESC;

-- Compter les messages par chat
SELECT 
    chat_id,
    COUNT(*) as message_count
FROM chat_messages
GROUP BY chat_id
ORDER BY message_count DESC;

-- Vérifier les chats pour un produit spécifique (remplacer par l'ID du produit)
SELECT 
    id,
    customer_id,
    customer_name,
    seller_id,
    seller_name,
    product_id,
    product_name,
    created_at
FROM chats
WHERE product_id = '1755356629542'  -- Remplacez par l'ID du produit que vous testez
ORDER BY created_at DESC;

-- Vérifier les messages pour un chat spécifique (remplacer par l'ID du chat)
SELECT 
    id,
    chat_id,
    sender_id,
    sender_name,
    sender_type,
    message,
    timestamp
FROM chat_messages
WHERE chat_id = '1755356841902'  -- Remplacez par l'ID du chat que vous testez
ORDER BY timestamp ASC;

-- Vérifier la structure des tables
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'chats'
ORDER BY ordinal_position;

SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'chat_messages'
ORDER BY ordinal_position;
