-- =====================================================
-- CORRECTION DES POLITIQUES RLS POUR LE TRACKING
-- Supprime les politiques existantes et les recrée
-- =====================================================

-- Supprimer toutes les politiques existantes sur driver_locations
DROP POLICY IF EXISTS "Drivers can view own location" ON driver_locations;
DROP POLICY IF EXISTS "Drivers can update own location" ON driver_locations;
DROP POLICY IF EXISTS "Drivers can insert own location" ON driver_locations;
DROP POLICY IF EXISTS "Clients can view assigned driver location" ON driver_locations;
DROP POLICY IF EXISTS "Admins can view all locations" ON driver_locations;
DROP POLICY IF EXISTS "Drivers can manage own location" ON driver_locations;

-- Supprimer toutes les politiques existantes sur delivery_assignments
DROP POLICY IF EXISTS "Drivers can view own assignments" ON delivery_assignments;
DROP POLICY IF EXISTS "Drivers can update own assignments" ON delivery_assignments;
DROP POLICY IF EXISTS "Clients can view order assignments" ON delivery_assignments;
DROP POLICY IF EXISTS "Drivers can manage own assignments" ON delivery_assignments;

-- =====================================================
-- CRÉER LES NOUVELLES POLITIQUES
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
-- VÉRIFICATION
-- =====================================================

-- Vérifier les politiques créées
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  cmd, 
  qual 
FROM pg_policies 
WHERE tablename IN ('driver_locations', 'delivery_assignments')
ORDER BY tablename, policyname;

-- =====================================================
-- MESSAGE DE SUCCÈS
-- =====================================================

SELECT '✅ Politiques RLS corrigées avec succès !' as status;


