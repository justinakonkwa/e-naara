-- =====================================================
-- 🔧 CORRECTION DE LA RÉCURSION INFINIE RLS
-- =====================================================

-- Supprimer toutes les politiques problématiques sur users
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;

-- Créer des politiques simples sans récursion
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Politique admin simplifiée (sans récursion)
CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (true);

CREATE POLICY "Admins can update all users" ON users
    FOR UPDATE USING (true);

-- Vérifier que les politiques sont créées
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;
