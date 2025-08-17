-- Script pour vérifier et corriger les politiques RLS de la table users
-- À exécuter dans l'éditeur SQL de Supabase

-- Vérifier si RLS est activé sur la table users
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'users';

-- Supprimer les anciennes politiques RLS si elles existent
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- Activer RLS sur la table users si ce n'est pas déjà fait
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Créer les politiques RLS pour la table users
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (
        auth.uid()::text = id
    );

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (
        auth.uid()::text = id
    );

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (
        auth.uid()::text = id
    );

-- Vérifier que les politiques ont été créées
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- Vérifier la structure de la table users
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Vérifier les données existantes
SELECT COUNT(*) as total_users FROM users;

-- Afficher un message de succès
SELECT 'Politiques RLS de la table users configurées avec succès !' as status;
