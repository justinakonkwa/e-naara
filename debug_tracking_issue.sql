-- =====================================================
-- 🔍 SCRIPT DE DEBUG POUR LE PROBLÈME DE TRACKING
-- =====================================================

-- 1. Vérifier la structure de la table driver_locations
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'driver_locations' 
ORDER BY ordinal_position;

-- 2. Lister toutes les positions de livreurs
SELECT 
    id,
    driver_id,
    latitude,
    longitude,
    is_online,
    last_updated,
    created_at
FROM driver_locations 
ORDER BY last_updated DESC 
LIMIT 10;

-- 3. Vérifier les positions pour le livreur spécifique
SELECT 
    id,
    driver_id,
    latitude,
    longitude,
    is_online,
    last_updated,
    created_at
FROM driver_locations 
WHERE driver_id = '1e87d033-767a-46e5-9764-df8f5c2a08ea'
ORDER BY last_updated DESC;

-- 4. Vérifier les positions en ligne
SELECT 
    id,
    driver_id,
    latitude,
    longitude,
    is_online,
    last_updated
FROM driver_locations 
WHERE is_online = true
ORDER BY last_updated DESC;

-- 5. Vérifier les politiques RLS sur driver_locations
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'driver_locations';

-- 6. Vérifier les permissions
SELECT 
    grantee,
    table_name,
    privilege_type
FROM information_schema.table_privileges 
WHERE table_name = 'driver_locations';

-- 7. Compter les enregistrements par livreur
SELECT 
    driver_id,
    COUNT(*) as total_positions,
    COUNT(CASE WHEN is_online = true THEN 1 END) as online_positions,
    MAX(last_updated) as last_position
FROM driver_locations 
GROUP BY driver_id
ORDER BY last_position DESC;

-- 8. Vérifier les vues utilisées
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('online_drivers', 'active_deliveries')
ORDER BY table_name;

-- 9. Tester une requête simple
SELECT COUNT(*) as total_driver_locations FROM driver_locations;

-- 10. Vérifier les utilisateurs avec le rôle driver
SELECT 
    id,
    email,
    role,
    created_at
FROM users 
WHERE role = 'driver'
ORDER BY created_at DESC;

