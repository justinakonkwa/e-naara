-- =====================================================
-- 🚚 CORRECTION DE LA TABLE ORDERS POUR LA GESTION DES LIVREURS
-- =====================================================

-- Ce script ajoute les colonnes manquantes pour la gestion des livreurs

-- Étape 1: Vérifier la structure actuelle de la table orders
SELECT 'Structure actuelle de la table orders:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Étape 2: Ajouter les colonnes manquantes pour la gestion des livreurs
DO $$ 
BEGIN
    -- Ajouter la colonne driver_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'driver_id') THEN
        ALTER TABLE orders ADD COLUMN driver_id UUID REFERENCES auth.users(id);
        RAISE NOTICE 'Colonne driver_id ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne driver_id existe déjà dans la table orders';
    END IF;
    
    -- Ajouter la colonne assigned_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'assigned_at') THEN
        ALTER TABLE orders ADD COLUMN assigned_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Colonne assigned_at ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne assigned_at existe déjà dans la table orders';
    END IF;
    
    -- Ajouter la colonne picked_up_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'picked_up_at') THEN
        ALTER TABLE orders ADD COLUMN picked_up_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Colonne picked_up_at ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne picked_up_at existe déjà dans la table orders';
    END IF;
    
    -- Ajouter la colonne delivered_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivered_at') THEN
        ALTER TABLE orders ADD COLUMN delivered_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Colonne delivered_at ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne delivered_at existe déjà dans la table orders';
    END IF;
    
    -- Ajouter la colonne shipping_latitude
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_latitude') THEN
        ALTER TABLE orders ADD COLUMN shipping_latitude DOUBLE PRECISION;
        RAISE NOTICE 'Colonne shipping_latitude ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne shipping_latitude existe déjà dans la table orders';
    END IF;
    
    -- Ajouter la colonne shipping_longitude
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_longitude') THEN
        ALTER TABLE orders ADD COLUMN shipping_longitude DOUBLE PRECISION;
        RAISE NOTICE 'Colonne shipping_longitude ajoutée à la table orders';
    ELSE
        RAISE NOTICE 'Colonne shipping_longitude existe déjà dans la table orders';
    END IF;
END $$;

-- Étape 3: Créer les index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_status_driver_id ON orders(status, driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_assigned_at ON orders(assigned_at);
CREATE INDEX IF NOT EXISTS idx_orders_picked_up_at ON orders(picked_up_at);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_at ON orders(delivered_at);
CREATE INDEX IF NOT EXISTS idx_orders_shipping_location ON orders(shipping_latitude, shipping_longitude);

-- Étape 4: Supprimer les anciennes politiques RLS si elles existent
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert own orders" ON orders;
DROP POLICY IF EXISTS "Drivers can view assigned orders" ON orders;
DROP POLICY IF EXISTS "Drivers can update assigned orders" ON orders;
DROP POLICY IF EXISTS "Drivers can view available orders" ON orders;
DROP POLICY IF EXISTS "Drivers can assign orders" ON orders;
DROP POLICY IF EXISTS "Drivers can mark as picked up" ON orders;
DROP POLICY IF EXISTS "Drivers can confirm delivery" ON orders;
DROP POLICY IF EXISTS "Drivers can cancel assignment" ON orders;

-- Étape 5: Créer les nouvelles politiques RLS
-- Politique pour permettre aux utilisateurs de voir leurs propres commandes
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

-- Politique pour permettre aux utilisateurs de mettre à jour leurs propres commandes
CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE USING (auth.uid() = user_id);

-- Politique pour permettre aux utilisateurs d'insérer leurs propres commandes
CREATE POLICY "Users can insert own orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politique pour permettre aux livreurs de voir les commandes assignées
CREATE POLICY "Drivers can view assigned orders" ON orders
    FOR SELECT USING (auth.uid() = driver_id);

-- Politique pour permettre aux livreurs de mettre à jour les commandes assignées
CREATE POLICY "Drivers can update assigned orders" ON orders
    FOR UPDATE USING (auth.uid() = driver_id);

-- Politique pour permettre aux livreurs de voir les commandes disponibles
CREATE POLICY "Drivers can view available orders" ON orders
    FOR SELECT USING (
        driver_id IS NULL 
        AND status IN ('pending', 'confirmed')
    );

-- Politique pour permettre aux livreurs d'assigner des commandes
CREATE POLICY "Drivers can assign orders" ON orders
    FOR UPDATE USING (
        driver_id IS NULL 
        AND status IN ('pending', 'confirmed')
    );

-- Politique pour permettre aux livreurs de marquer comme récupérées
CREATE POLICY "Drivers can mark as picked up" ON orders
    FOR UPDATE USING (
        auth.uid() = driver_id 
        AND status = 'assigned'
    );

-- Politique pour permettre aux livreurs de confirmer la livraison
CREATE POLICY "Drivers can confirm delivery" ON orders
    FOR UPDATE USING (
        auth.uid() = driver_id 
        AND status IN ('picked_up', 'in_transit')
    );

-- Politique pour permettre aux livreurs d'annuler l'assignation
CREATE POLICY "Drivers can cancel assignment" ON orders
    FOR UPDATE USING (
        auth.uid() = driver_id 
        AND status IN ('assigned', 'picked_up')
    );

-- Étape 6: Ajouter des commentaires sur les nouvelles colonnes
COMMENT ON COLUMN orders.driver_id IS 'ID du livreur assigné à cette commande';
COMMENT ON COLUMN orders.assigned_at IS 'Date et heure d''assignation de la commande au livreur';
COMMENT ON COLUMN orders.picked_up_at IS 'Date et heure de récupération de la commande par le livreur';
COMMENT ON COLUMN orders.delivered_at IS 'Date et heure de livraison confirmée';
COMMENT ON COLUMN orders.shipping_latitude IS 'Latitude de l''adresse de livraison';
COMMENT ON COLUMN orders.shipping_longitude IS 'Longitude de l''adresse de livraison';

-- Étape 7: Vérifier la structure finale
SELECT 'Structure finale de la table orders:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Étape 8: Vérifier les politiques RLS
SELECT 'Politiques RLS créées:' as info;

SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- Étape 9: Statistiques des commandes
SELECT 'Statistiques des commandes:' as info;

SELECT 
    COUNT(*) as total_orders,
    COUNT(CASE WHEN driver_id IS NOT NULL THEN 1 END) as assigned_orders,
    COUNT(CASE WHEN driver_id IS NULL THEN 1 END) as unassigned_orders,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_orders,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_orders,
    COUNT(CASE WHEN status = 'assigned' THEN 1 END) as assigned_status_orders,
    COUNT(CASE WHEN status = 'picked_up' THEN 1 END) as picked_up_orders,
    COUNT(CASE WHEN status = 'in_transit' THEN 1 END) as in_transit_orders,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_orders
FROM orders;

-- Message de confirmation
SELECT '✅ Table orders corrigée pour la gestion des livreurs!' as message;
