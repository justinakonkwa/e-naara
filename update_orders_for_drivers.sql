-- =====================================================
-- 🚚 MISE À JOUR DE LA TABLE ORDERS POUR LA GESTION DES LIVREURS
-- =====================================================

-- Ajouter les colonnes nécessaires pour la gestion des livreurs
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS picked_up_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP WITH TIME ZONE;

-- Ajouter des index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_status_driver_id ON orders(status, driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_assigned_at ON orders(assigned_at);
CREATE INDEX IF NOT EXISTS idx_orders_picked_up_at ON orders(picked_up_at);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_at ON orders(delivered_at);

-- Mettre à jour les politiques RLS pour permettre aux livreurs d'accéder aux commandes
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Drivers can view assigned orders" ON orders;
DROP POLICY IF EXISTS "Drivers can update assigned orders" ON orders;
DROP POLICY IF EXISTS "Drivers can view available orders" ON orders;
DROP POLICY IF EXISTS "Drivers can assign orders" ON orders;
DROP POLICY IF EXISTS "Drivers can mark as picked up" ON orders;
DROP POLICY IF EXISTS "Drivers can confirm delivery" ON orders;
DROP POLICY IF EXISTS "Drivers can cancel assignment" ON orders;

-- Politique pour permettre aux utilisateurs de voir leurs propres commandes
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

-- Politique pour permettre aux utilisateurs de mettre à jour leurs propres commandes
CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE USING (auth.uid() = user_id);

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

-- Commentaires sur les nouvelles colonnes
COMMENT ON COLUMN orders.driver_id IS 'ID du livreur assigné à cette commande';
COMMENT ON COLUMN orders.assigned_at IS 'Date et heure d''assignation de la commande au livreur';
COMMENT ON COLUMN orders.picked_up_at IS 'Date et heure de récupération de la commande par le livreur';
COMMENT ON COLUMN orders.delivered_at IS 'Date et heure de livraison confirmée';

-- =====================================================
-- 📋 STATUTS DE COMMANDE SUPPORTÉS
-- =====================================================
/*
Statuts disponibles :
- 'pending' : En attente de confirmation
- 'confirmed' : Confirmée, prête pour livraison
- 'assigned' : Assignée à un livreur
- 'picked_up' : Récupérée par le livreur
- 'in_transit' : En cours de livraison
- 'delivered' : Livrée avec succès
- 'cancelled' : Annulée
*/

-- =====================================================
-- 🔍 REQUÊTES UTILES POUR LES TESTS
-- =====================================================

-- Voir toutes les commandes disponibles pour livraison
-- SELECT * FROM orders WHERE driver_id IS NULL AND status IN ('pending', 'confirmed');

-- Voir les commandes assignées à un livreur spécifique
-- SELECT * FROM orders WHERE driver_id = 'user_id_here' AND status IN ('assigned', 'picked_up', 'in_transit');

-- Voir les commandes livrées récemment
-- SELECT * FROM orders WHERE status = 'delivered' ORDER BY delivered_at DESC LIMIT 10;

-- Statistiques des livreurs
-- SELECT 
--     driver_id,
--     COUNT(*) as total_orders,
--     COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_orders,
--     AVG(EXTRACT(EPOCH FROM (delivered_at - assigned_at))/3600) as avg_delivery_hours
-- FROM orders 
-- WHERE driver_id IS NOT NULL 
-- GROUP BY driver_id;
