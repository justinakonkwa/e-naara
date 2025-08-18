-- =====================================================
-- SYSTÈME DE TRACKING EN TEMPS RÉEL
-- Configuration de la base de données Supabase
-- =====================================================

-- Table pour les positions GPS des livreurs
CREATE TABLE IF NOT EXISTS driver_locations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  driver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  accuracy DECIMAL(5, 2),
  speed DECIMAL(5, 2),
  heading INTEGER,
  battery_level INTEGER,
  is_online BOOLEAN DEFAULT true,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table pour les assignations livreur-commande
CREATE TABLE IF NOT EXISTS delivery_assignments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  driver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  estimated_delivery_time TIMESTAMP WITH TIME ZONE,
  actual_delivery_time TIMESTAMP WITH TIME ZONE,
  status VARCHAR(50) DEFAULT 'assigned',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_driver_locations_driver_id ON driver_locations(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_locations_last_updated ON driver_locations(last_updated);
CREATE INDEX IF NOT EXISTS idx_driver_locations_is_online ON driver_locations(is_online);
CREATE INDEX IF NOT EXISTS idx_delivery_assignments_order_id ON delivery_assignments(order_id);
CREATE INDEX IF NOT EXISTS idx_delivery_assignments_driver_id ON delivery_assignments(driver_id);
CREATE INDEX IF NOT EXISTS idx_delivery_assignments_status ON delivery_assignments(status);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Activer RLS sur les tables
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_assignments ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLICIES POUR driver_locations
-- =====================================================

-- Les livreurs peuvent voir et modifier leur propre position
CREATE POLICY "Drivers can view own location" ON driver_locations
  FOR SELECT USING (auth.uid() = driver_id);

CREATE POLICY "Drivers can update own location" ON driver_locations
  FOR UPDATE USING (auth.uid() = driver_id);

CREATE POLICY "Drivers can insert own location" ON driver_locations
  FOR INSERT WITH CHECK (auth.uid() = driver_id);

-- Les clients peuvent voir la position du livreur assigné à leur commande
CREATE POLICY "Clients can view assigned driver location" ON driver_locations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM delivery_assignments da
      JOIN orders o ON da.order_id = o.id
      WHERE da.driver_id = driver_locations.driver_id
      AND o.user_id = auth.uid()
      AND da.status IN ('assigned', 'picked_up', 'out_for_delivery')
    )
  );

-- Les admins peuvent voir toutes les positions
CREATE POLICY "Admins can view all locations" ON driver_locations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

-- =====================================================
-- POLICIES POUR delivery_assignments
-- =====================================================

-- Les livreurs peuvent voir leurs assignations
CREATE POLICY "Drivers can view own assignments" ON delivery_assignments
  FOR SELECT USING (auth.uid() = driver_id);

-- Les livreurs peuvent mettre à jour leurs assignations
CREATE POLICY "Drivers can update own assignments" ON delivery_assignments
  FOR UPDATE USING (auth.uid() = driver_id);

-- Les clients peuvent voir les assignations de leurs commandes
CREATE POLICY "Clients can view order assignments" ON delivery_assignments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = delivery_assignments.order_id
      AND orders.user_id = auth.uid()
    )
  );

-- Les admins peuvent tout faire
CREATE POLICY "Admins can manage all assignments" ON delivery_assignments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

-- =====================================================
-- FONCTIONS UTILITAIRES
-- =====================================================

-- Fonction pour calculer la distance entre deux points GPS
CREATE OR REPLACE FUNCTION calculate_distance(
  lat1 DECIMAL,
  lon1 DECIMAL,
  lat2 DECIMAL,
  lon2 DECIMAL
) RETURNS DECIMAL AS $$
BEGIN
  RETURN (
    6371 * acos(
      cos(radians(lat1)) * cos(radians(lat2)) *
      cos(radians(lon2) - radians(lon1)) +
      sin(radians(lat1)) * sin(radians(lat2))
    )
  );
END;
$$ LANGUAGE plpgsql;

-- Fonction pour nettoyer les anciennes positions (plus de 24h)
CREATE OR REPLACE FUNCTION cleanup_old_locations()
RETURNS void AS $$
BEGIN
  DELETE FROM driver_locations 
  WHERE last_updated < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger pour mettre à jour last_updated automatiquement
CREATE OR REPLACE FUNCTION update_last_updated()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_updated = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_driver_locations_last_updated
  BEFORE UPDATE ON driver_locations
  FOR EACH ROW
  EXECUTE FUNCTION update_last_updated();

-- =====================================================
-- VUES UTILES
-- =====================================================

-- Vue pour les livreurs en ligne avec leur dernière position
CREATE OR REPLACE VIEW online_drivers AS
SELECT DISTINCT ON (dl.driver_id)
  dl.driver_id,
  dl.latitude,
  dl.longitude,
  dl.accuracy,
  dl.speed,
  dl.heading,
  dl.battery_level,
  dl.last_updated,
  u.raw_user_meta_data->>'display_name' as driver_name,
  u.email as driver_email
FROM driver_locations dl
JOIN auth.users u ON dl.driver_id = u.id
WHERE dl.is_online = true
ORDER BY dl.driver_id, dl.last_updated DESC;

-- Vue pour les livraisons actives avec position du livreur
CREATE OR REPLACE VIEW active_deliveries AS
SELECT 
  da.id as assignment_id,
  da.order_id,
  da.driver_id,
  da.assigned_at,
  da.estimated_delivery_time,
  da.status,
  da.notes,
  o.total_amount,
  o.shipping_address,
  o.user_id as customer_id,
  dl.latitude,
  dl.longitude,
  dl.last_updated as driver_last_seen,
  u.raw_user_meta_data->>'display_name' as driver_name,
  u.email as driver_email
FROM delivery_assignments da
JOIN orders o ON da.order_id = o.id
LEFT JOIN driver_locations dl ON da.driver_id = dl.driver_id
LEFT JOIN auth.users u ON da.driver_id = u.id
WHERE da.status IN ('assigned', 'picked_up', 'out_for_delivery')
ORDER BY da.assigned_at DESC;

-- =====================================================
-- DONNÉES DE TEST (optionnel)
-- =====================================================

-- Insérer quelques positions de test pour les livreurs
-- (à décommenter si vous voulez des données de test)

/*
INSERT INTO driver_locations (driver_id, latitude, longitude, accuracy, speed, heading, battery_level, is_online)
VALUES 
  ('00000000-0000-0000-0000-000000000001', 48.8566, 2.3522, 5.0, 25.0, 180, 85, true),
  ('00000000-0000-0000-0000-000000000002', 48.8584, 2.2945, 3.0, 0.0, 0, 92, true);
*/

-- =====================================================
-- COMMENTAIRES ET DOCUMENTATION
-- =====================================================

COMMENT ON TABLE driver_locations IS 'Positions GPS des livreurs en temps réel';
COMMENT ON TABLE delivery_assignments IS 'Assignations des commandes aux livreurs';
COMMENT ON VIEW online_drivers IS 'Vue des livreurs actuellement en ligne';
COMMENT ON VIEW active_deliveries IS 'Vue des livraisons actives avec position du livreur';

-- =====================================================
-- VÉRIFICATION DE LA CONFIGURATION
-- =====================================================

-- Vérifier que les tables ont été créées
SELECT 
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('driver_locations', 'delivery_assignments');

-- Vérifier les politiques RLS
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename IN ('driver_locations', 'delivery_assignments');

-- Vérifier les index
SELECT 
  indexname,
  tablename,
  indexdef
FROM pg_indexes 
WHERE tablename IN ('driver_locations', 'delivery_assignments');


