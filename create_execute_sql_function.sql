-- =====================================================
-- 🔧 FONCTION POUR EXÉCUTER DES REQUÊTES SQL BRUTES
-- =====================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS execute_sql(TEXT);

-- Fonction pour exécuter des requêtes SQL brutes
CREATE OR REPLACE FUNCTION execute_sql(sql_query TEXT)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    -- Exécuter la requête SQL brute
    EXECUTE sql_query INTO result;
    
    -- Retourner le résultat
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- En cas d'erreur, retourner un message d'erreur
        RETURN json_build_object(
            'error', SQLERRM,
            'sql_state', SQLSTATE,
            'sql_query', sql_query
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION execute_sql(TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction execute_sql créée avec succès' as message;

-- Test avec une requête simple
SELECT execute_sql('SELECT 1 as test');

