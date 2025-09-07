-- =====================================================
-- 🔧 FONCTION POUR EXÉCUTER DES REQUÊTES SQL BRUTES
-- =====================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS direct_sql_update(TEXT);

-- Fonction pour exécuter des requêtes SQL brutes
CREATE OR REPLACE FUNCTION direct_sql_update(sql_query TEXT)
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
            'sql_state', SQLSTATE
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION direct_sql_update(TEXT) TO authenticated;

-- Test de la fonction
SELECT '✅ Fonction direct_sql_update créée avec succès' as message;

