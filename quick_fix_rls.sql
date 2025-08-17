-- =====================================================
-- 🚨 CORRECTION RAPIDE - RÉCURSION INFINIE
-- =====================================================

-- Désactiver temporairement RLS sur users
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;

-- Réactiver RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

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
SELECT 'Politiques créées' as status, COUNT(*) as count
FROM pg_policies 
WHERE tablename = 'users';
