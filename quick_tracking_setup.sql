-- =====================================================
-- CONFIGURATION RAPIDE DU SYSTÈME DE TRACKING
-- Script simplifié pour tester rapidement
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
-- ROW LEVEL SECURITY (RLS) POLICIES SIMPLIFIÉES
-- =====================================================

-- Activer RLS sur les tables
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_assignments ENABLE ROW LEVEL SECURITY;

-- Politiques simplifiées pour les tests
-- Les livreurs peuvent tout faire sur leur position
CREATE POLICY "Drivers can manage own location" ON driver_locations
  FOR ALL USING (auth.uid() = driver_id);

-- Les clients peuvent voir la position du livreur assigné
CREATE POLICY "Clients can view assigned driver location" ON driver_locations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM delivery_assignments da
      JOIN orders o ON da.order_id = o.id
      WHERE da.driver_id = driver_locations.driver_id
      AND o.user_id = auth.uid()
    )
  );

-- Les livreurs peuvent gérer leurs assignations
CREATE POLICY "Drivers can manage own assignments" ON delivery_assignments
  FOR ALL USING (auth.uid() = driver_id);

-- Les clients peuvent voir les assignations de leurs commandes
CREATE POLICY "Clients can view order assignments" ON delivery_assignments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = delivery_assignments.order_id
      AND o.user_id = auth.uid()
    )
  );

-- =====================================================
-- DONNÉES DE TEST
-- =====================================================

-- Insérer une position de test pour un livreur (remplacez l'ID par un vrai ID de livreur)
-- INSERT INTO driver_locations (driver_id, latitude, longitude, accuracy, speed, heading, is_online)
-- VALUES (
--   'VOTRE_ID_LIVREUR_ICI',
--   48.8566,  -- Latitude Paris
--   2.3522,   -- Longitude Paris
--   10.0,     -- Précision 10m
--   0.0,      -- Vitesse 0 km/h
--   0,        -- Direction 0°
--   true      -- En ligne
-- );

-- =====================================================
-- VÉRIFICATION
-- =====================================================

-- Vérifier que les tables sont créées
SELECT 'driver_locations' as table_name, COUNT(*) as row_count FROM driver_locations
UNION ALL
SELECT 'delivery_assignments' as table_name, COUNT(*) as row_count FROM delivery_assignments;

-- Vérifier les politiques RLS
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('driver_locations', 'delivery_assignments');

-- =====================================================
-- MESSAGE DE SUCCÈS
-- =====================================================

-- Afficher un message de succès
SELECT '✅ Configuration du système de tracking terminée avec succès !' as status;


