-- Script pour mettre à jour la table chat_messages avec support des réponses
-- À exécuter dans l'éditeur SQL de Supabase

-- Ajouter les colonnes pour les réponses aux messages
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS reply_to_message_id TEXT,
ADD COLUMN IF NOT EXISTS reply_to_message_text TEXT;

-- Ajouter des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_chat_messages_reply_to 
ON chat_messages(reply_to_message_id);

-- Vérifier la structure mise à jour
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'chat_messages'
ORDER BY ordinal_position;

-- Vérifier les données existantes
SELECT 
    id,
    chat_id,
    sender_id,
    sender_name,
    message,
    type,
    reply_to_message_id,
    reply_to_message_text,
    timestamp
FROM chat_messages
ORDER BY timestamp DESC
LIMIT 10;

-- Afficher un message de succès
SELECT 'Table chat_messages mise à jour avec succès !' as status;
