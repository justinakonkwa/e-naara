-- =====================================================
-- 🎭 AJOUT DE LA GESTION DES RÔLES UTILISATEUR
-- =====================================================

-- Ajouter la colonne role à la table users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'driver', 'admin'));

-- Ajouter un index pour optimiser les requêtes par rôle
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Mettre à jour les politiques RLS pour les rôles
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;

-- Politique pour permettre aux utilisateurs de voir leur propre profil
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (auth.uid() = id);

-- Politique pour permettre aux utilisateurs de mettre à jour leur propre profil
CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Politique pour permettre aux administrateurs de voir tous les utilisateurs
CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Politique pour permettre aux administrateurs de mettre à jour tous les utilisateurs
CREATE POLICY "Admins can update all users" ON users
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Commentaire sur la colonne role
COMMENT ON COLUMN users.role IS 'Rôle de l''utilisateur: user, driver, ou admin';

-- =====================================================
-- 📋 RÔLES DISPONIBLES
-- =====================================================
/*
Rôles disponibles :
- 'user' : Client normal (par défaut)
- 'driver' : Livreur (accès aux fonctionnalités de livraison)
- 'admin' : Administrateur (accès complet)
*/

-- =====================================================
-- 🔍 REQUÊTES UTILES POUR LES TESTS
-- =====================================================

-- Voir tous les utilisateurs et leurs rôles
-- SELECT id, email, first_name, last_name, role, created_at FROM users ORDER BY created_at DESC;

-- Voir tous les livreurs
-- SELECT id, email, first_name, last_name, created_at FROM users WHERE role = 'driver';

-- Voir tous les administrateurs
-- SELECT id, email, first_name, last_name, created_at FROM users WHERE role = 'admin';

-- Statistiques des rôles
-- SELECT role, COUNT(*) as count FROM users GROUP BY role ORDER BY count DESC;

-- =====================================================
-- 🚀 MISE À JOUR DES UTILISATEURS EXISTANTS
-- =====================================================

-- Optionnel : Mettre à jour les utilisateurs existants sans rôle
-- UPDATE users SET role = 'user' WHERE role IS NULL;

-- Optionnel : Créer un administrateur par défaut (remplacez par l'email souhaité)
-- UPDATE users SET role = 'admin' WHERE email = 'admin@example.com';
