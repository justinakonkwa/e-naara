-- Script final pour les tables de chat (version simplifiée)

-- Supprimer les anciennes politiques RLS
DROP POLICY IF EXISTS "Users can view their own chats" ON chats;
DROP POLICY IF EXISTS "Users can insert their own chats" ON chats;
DROP POLICY IF EXISTS "Users can update their own chats" ON chats;

DROP POLICY IF EXISTS "Users can view messages in their chats" ON chat_messages;
DROP POLICY IF EXISTS "Users can insert messages in their chats" ON chat_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;

DROP POLICY IF EXISTS "Users can view their own notifications" ON chat_notifications;
DROP POLICY IF EXISTS "Users can insert notifications" ON chat_notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON chat_notifications;

-- Supprimer les anciens triggers
DROP TRIGGER IF EXISTS trigger_update_chat_last_message ON chat_messages;
DROP TRIGGER IF EXISTS trigger_increment_unread_count ON chat_messages;
DROP TRIGGER IF EXISTS trigger_create_chat_notification ON chat_messages;

-- Supprimer les anciennes fonctions
DROP FUNCTION IF EXISTS update_chat_last_message();
DROP FUNCTION IF EXISTS increment_unread_count();
DROP FUNCTION IF EXISTS create_chat_notification();

-- Supprimer les anciennes tables (attention : cela supprimera toutes les données)
DROP TABLE IF EXISTS chat_notifications CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chats CASCADE;

-- Maintenant créer les nouvelles tables
-- Table des chats
CREATE TABLE IF NOT EXISTS chats (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    seller_id TEXT NOT NULL,
    seller_name TEXT NOT NULL,
    product_id TEXT NOT NULL,
    product_name TEXT NOT NULL,
    product_image_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    unread_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived', 'blocked'))
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_chats_customer_id ON chats(customer_id);
CREATE INDEX IF NOT EXISTS idx_chats_seller_id ON chats(seller_id);
CREATE INDEX IF NOT EXISTS idx_chats_product_id ON chats(product_id);
CREATE INDEX IF NOT EXISTS idx_chats_last_message_at ON chats(last_message_at);
CREATE INDEX IF NOT EXISTS idx_chats_status ON chats(status);

-- Table des messages de chat
CREATE TABLE IF NOT EXISTS chat_messages (
    id TEXT PRIMARY KEY,
    chat_id TEXT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL,
    sender_name TEXT NOT NULL,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('customer', 'seller')),
    message TEXT NOT NULL,
    image_url TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE,
    type TEXT DEFAULT 'text' CHECK (type IN ('text', 'image', 'file', 'system'))
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_id ON chat_messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_timestamp ON chat_messages(timestamp);
CREATE INDEX IF NOT EXISTS idx_chat_messages_is_read ON chat_messages(is_read);

-- Table des notifications de chat (RLS désactivé pour simplifier)
CREATE TABLE IF NOT EXISTS chat_notifications (
    id TEXT PRIMARY KEY,
    chat_id TEXT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_chat_notifications_user_id ON chat_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_notifications_chat_id ON chat_notifications(chat_id);
CREATE INDEX IF NOT EXISTS idx_chat_notifications_timestamp ON chat_notifications(timestamp);
CREATE INDEX IF NOT EXISTS idx_chat_notifications_is_read ON chat_notifications(is_read);

-- Politiques de sécurité RLS (Row Level Security)

-- Activer RLS sur les tables principales
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Désactiver RLS sur les notifications pour éviter les problèmes
ALTER TABLE chat_notifications DISABLE ROW LEVEL SECURITY;

-- Politiques pour la table chats
CREATE POLICY "Users can view their own chats" ON chats
    FOR SELECT USING (
        auth.uid()::text = customer_id OR auth.uid()::text = seller_id
    );

CREATE POLICY "Users can insert their own chats" ON chats
    FOR INSERT WITH CHECK (
        auth.uid()::text = customer_id OR auth.uid()::text = seller_id
    );

CREATE POLICY "Users can update their own chats" ON chats
    FOR UPDATE USING (
        auth.uid()::text = customer_id OR auth.uid()::text = seller_id
    );

-- Politiques pour la table chat_messages
CREATE POLICY "Users can view messages in their chats" ON chat_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM chats 
            WHERE chats.id = chat_messages.chat_id 
            AND (chats.customer_id = auth.uid()::text OR chats.seller_id = auth.uid()::text)
        )
    );

CREATE POLICY "Users can insert messages in their chats" ON chat_messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM chats 
            WHERE chats.id = chat_messages.chat_id 
            AND (chats.customer_id = auth.uid()::text OR chats.seller_id = auth.uid()::text)
        )
        AND sender_id = auth.uid()::text
    );

CREATE POLICY "Users can update their own messages" ON chat_messages
    FOR UPDATE USING (
        sender_id = auth.uid()::text
    );

-- Fonction pour mettre à jour le timestamp du dernier message
CREATE OR REPLACE FUNCTION update_chat_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE chats 
    SET last_message_at = NEW.timestamp
    WHERE id = NEW.chat_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour automatiquement le timestamp
CREATE TRIGGER trigger_update_chat_last_message
    AFTER INSERT ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_last_message();

-- Fonction pour incrémenter le compteur de messages non lus
CREATE OR REPLACE FUNCTION increment_unread_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE chats 
    SET unread_count = unread_count + 1
    WHERE id = NEW.chat_id
    AND (
        (NEW.sender_type = 'customer' AND seller_id != NEW.sender_id)
        OR (NEW.sender_type = 'seller' AND customer_id != NEW.sender_id)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour incrémenter automatiquement le compteur
CREATE TRIGGER trigger_increment_unread_count
    AFTER INSERT ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION increment_unread_count();

-- Commentaires pour documenter les tables
COMMENT ON TABLE chats IS 'Table des conversations entre clients et vendeurs';
COMMENT ON TABLE chat_messages IS 'Table des messages dans les conversations';
COMMENT ON TABLE chat_notifications IS 'Table des notifications de chat pour les utilisateurs (RLS désactivé)';

COMMENT ON COLUMN chats.customer_id IS 'ID de l''utilisateur client';
COMMENT ON COLUMN chats.seller_id IS 'ID de l''utilisateur vendeur';
COMMENT ON COLUMN chats.product_id IS 'ID du produit concerné par la conversation';
COMMENT ON COLUMN chats.unread_count IS 'Nombre de messages non lus dans cette conversation';

COMMENT ON COLUMN chat_messages.sender_type IS 'Type d''expéditeur: customer ou seller';
COMMENT ON COLUMN chat_messages.type IS 'Type de message: text, image, file, ou system';
COMMENT ON COLUMN chat_messages.is_read IS 'Indique si le message a été lu par le destinataire';




