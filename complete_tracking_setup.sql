-- =====================================================
-- CONFIGURATION COMPLÈTE DU SYSTÈME DE TRACKING
-- Gère tous les conflits et crée un système fonctionnel
-- =====================================================

-- =====================================================
-- ÉTAPE 1: CRÉER LES TABLES (SI ELLES N'EXISTENT PAS)
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

-- =====================================================
-- ÉTAPE 2: CRÉER LES INDEX (SI ILS N'EXISTENT PAS)
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_driver_locations_driver_id ON driver_locations(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_locations_last_updated ON driver_locations(last_updated);
CREATE INDEX IF NOT EXISTS idx_driver_locations_is_online ON driver_locations(is_online);
CREATE INDEX IF NOT EXISTS idx_delivery_assignments_order_id ON delivery_assignments(order_id);
CREATE INDEX IF NOT EXISTS idx_delivery_assignments_driver_id ON delivery_assignments(driver_id);
CREATE INDEX IF NOT EXISTS idx_delivery_assignments_status ON delivery_assignments(status);

-- =====================================================
-- ÉTAPE 3: ACTIVER RLS
-- =====================================================

ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_assignments ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- ÉTAPE 4: SUPPRIMER TOUTES LES POLITIQUES EXISTANTES
-- =====================================================

-- Supprimer toutes les politiques sur driver_locations
DROP POLICY IF EXISTS "Drivers can view own location" ON driver_locations;
DROP POLICY IF EXISTS "Drivers can update own location" ON driver_locations;
DROP POLICY IF EXISTS "Drivers can insert own location" ON driver_locations;
DROP POLICY IF EXISTS "Clients can view assigned driver location" ON driver_locations;
DROP POLICY IF EXISTS "Admins can view all locations" ON driver_locations;
DROP POLICY IF EXISTS "Drivers can manage own location" ON driver_locations;
DROP POLICY IF EXISTS "Drivers can view assigned orders" ON driver_locations;
DROP POLICY IF EXISTS "Drivers can update assigned orders" ON driver_locations;
DROP POLICY IF EXISTS "Drivers can insert assigned orders" ON driver_locations;
DROP POLICY IF EXISTS "Drivers can delete assigned orders" ON driver_locations;

-- Supprimer toutes les politiques sur delivery_assignments
DROP POLICY IF EXISTS "Drivers can view own assignments" ON delivery_assignments;
DROP POLICY IF EXISTS "Drivers can update own assignments" ON delivery_assignments;
DROP POLICY IF EXISTS "Drivers can insert own assignments" ON delivery_assignments;
DROP POLICY IF EXISTS "Drivers can delete own assignments" ON delivery_assignments;
DROP POLICY IF EXISTS "Clients can view order assignments" ON delivery_assignments;
DROP POLICY IF EXISTS "Drivers can manage own assignments" ON delivery_assignments;
DROP POLICY IF EXISTS "Admins can view all assignments" ON delivery_assignments;
DROP POLICY IF EXISTS "Admins can manage all assignments" ON delivery_assignments;

-- =====================================================
-- ÉTAPE 5: CRÉER LES NOUVELLES POLITIQUES
-- =====================================================

-- Politiques pour driver_locations
CREATE POLICY "Drivers can manage own location" ON driver_locations
  FOR ALL USING (auth.uid() = driver_id);

CREATE POLICY "Clients can view assigned driver location" ON driver_locations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM delivery_assignments da
      JOIN orders o ON da.order_id = o.id
      WHERE da.driver_id = driver_locations.driver_id
      AND o.user_id = auth.uid()
    )
  );

-- Politiques pour delivery_assignments
CREATE POLICY "Drivers can manage own assignments" ON delivery_assignments
  FOR ALL USING (auth.uid() = driver_id);

CREATE POLICY "Clients can view order assignments" ON delivery_assignments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = delivery_assignments.order_id
      AND o.user_id = auth.uid()
    )
  );

-- =====================================================
-- ÉTAPE 6: VÉRIFICATION
-- =====================================================

-- Vérifier que les tables existent
SELECT 
  'Tables créées' as check_type,
  COUNT(*) as count
FROM information_schema.tables 
WHERE table_name IN ('driver_locations', 'delivery_assignments')
  AND table_schema = 'public';

-- Vérifier les politiques RLS
SELECT 
  'Politiques RLS' as check_type,
  COUNT(*) as count
FROM pg_policies 
WHERE tablename IN ('driver_locations', 'delivery_assignments');

-- Vérifier les index
SELECT 
  'Index créés' as check_type,
  COUNT(*) as count
FROM pg_indexes 
WHERE tablename IN ('driver_locations', 'delivery_assignments');

-- =====================================================
-- ÉTAPE 7: MESSAGE DE SUCCÈS
-- =====================================================

SELECT '🎉 Configuration complète du système de tracking terminée avec succès !' as status;
SELECT '📱 Le système est maintenant prêt à être utilisé par les livreurs et clients.' as message;


