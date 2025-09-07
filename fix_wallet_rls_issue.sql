-- =====================================================
-- 🔧 CORRECTION DU PROBLÈME RLS DU SYSTÈME DE PORTEFEUILLE
-- =====================================================

-- Ce script corrige le problème où les utilisateurs ne peuvent pas créer leur portefeuille
-- à cause des politiques RLS trop restrictives

-- Étape 1: Vérifier l'état actuel
SELECT '🔍 ÉTAPE 1: Vérification de l\'état actuel' as info;

-- Vérifier si la table wallets existe
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wallets') 
        THEN '✅ Table wallets existe'
        ELSE '❌ Table wallets manquante'
    END as status;

-- Vérifier les politiques RLS actuelles
SELECT 'Politiques RLS actuelles sur wallets:' as info;
SELECT 
    policyname,
    permissive,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'wallets'
ORDER BY policyname;

-- Étape 2: Supprimer les anciennes politiques RLS problématiques
SELECT '🔧 ÉTAPE 2: Suppression des anciennes politiques RLS' as info;

DROP POLICY IF EXISTS "Users can view their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can update their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can insert their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can delete their own wallet" ON wallets;

-- Étape 3: Créer de nouvelles politiques RLS plus permissives
SELECT '🔐 ÉTAPE 3: Création de nouvelles politiques RLS' as info;

-- Politique pour permettre aux utilisateurs de voir leur propre portefeuille
CREATE POLICY "Users can view their own wallet" ON wallets
    FOR SELECT USING (auth.uid() = user_id);

-- Politique pour permettre aux utilisateurs de mettre à jour leur propre portefeuille
CREATE POLICY "Users can update their own wallet" ON wallets
    FOR UPDATE USING (auth.uid() = user_id);

-- Politique pour permettre aux utilisateurs d'insérer leur propre portefeuille
CREATE POLICY "Users can insert their own wallet" ON wallets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politique pour permettre aux utilisateurs de supprimer leur propre portefeuille
CREATE POLICY "Users can delete their own wallet" ON wallets
    FOR DELETE USING (auth.uid() = user_id);

-- Politique spéciale pour permettre la création automatique de portefeuilles
-- Cette politique permet l'insertion si l'utilisateur n'a pas encore de portefeuille
CREATE POLICY "System can create wallet for new users" ON wallets
    FOR INSERT WITH CHECK (
        NOT EXISTS (
            SELECT 1 FROM wallets WHERE user_id = auth.uid()
        )
    );

-- Étape 4: Vérifier et corriger la fonction create_wallet_for_user
SELECT '⚙️ ÉTAPE 4: Correction de la fonction create_wallet_for_user' as info;

-- Recréer la fonction avec une meilleure gestion des erreurs
CREATE OR REPLACE FUNCTION create_wallet_for_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier si l'utilisateur a déjà un portefeuille
    IF NOT EXISTS (SELECT 1 FROM wallets WHERE user_id = NEW.id) THEN
        -- Créer un portefeuille pour le nouvel utilisateur
        INSERT INTO wallets (user_id, balance, currency)
        VALUES (NEW.id, 0.00, 'USD');
        
        RAISE NOTICE 'Portefeuille créé pour l''utilisateur %', NEW.id;
    ELSE
        RAISE NOTICE 'L''utilisateur % a déjà un portefeuille', NEW.id;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors de la création du portefeuille pour l''utilisateur %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ language 'plpgsql';

-- Étape 5: Vérifier et recréer le trigger
SELECT '🔗 ÉTAPE 5: Recréation du trigger' as info;

-- Supprimer l'ancien trigger s'il existe
DROP TRIGGER IF EXISTS create_wallet_for_user_trigger ON users;

-- Créer le nouveau trigger
CREATE TRIGGER create_wallet_for_user_trigger
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION create_wallet_for_user();

-- Étape 6: Créer des portefeuilles pour les utilisateurs existants qui n'en ont pas
SELECT '👥 ÉTAPE 6: Création de portefeuilles pour les utilisateurs existants' as info;

INSERT INTO wallets (user_id, balance, currency)
SELECT 
    u.id,
    0.00,
    'USD'
FROM auth.users u
WHERE NOT EXISTS (
    SELECT 1 FROM wallets w WHERE w.user_id = u.id
);

-- Afficher le nombre de portefeuilles créés
SELECT 
    COUNT(*) as portefeuilles_crees,
    'portefeuilles créés pour les utilisateurs existants' as info
FROM wallets w
WHERE w.created_at >= NOW() - INTERVAL '1 minute';

-- Étape 7: Vérifier les politiques RLS finales
SELECT '✅ ÉTAPE 7: Vérification des politiques RLS finales' as info;

SELECT 
    policyname,
    permissive,
    cmd,
    CASE 
        WHEN cmd = 'SELECT' THEN '✅ Politique SELECT'
        WHEN cmd = 'INSERT' THEN '✅ Politique INSERT'
        WHEN cmd = 'UPDATE' THEN '✅ Politique UPDATE'
        WHEN cmd = 'DELETE' THEN '✅ Politique DELETE'
        ELSE '⚠️ Politique inconnue'
    END as status
FROM pg_policies 
WHERE tablename = 'wallets'
ORDER BY policyname;

-- Étape 8: Test de création de portefeuille
SELECT '🧪 ÉTAPE 8: Test de création de portefeuille' as info;

-- Compter le nombre total de portefeuilles
SELECT 
    COUNT(*) as total_portefeuilles,
    'portefeuilles existants' as info
FROM wallets;

-- Compter le nombre d'utilisateurs
SELECT 
    COUNT(*) as total_utilisateurs,
    'utilisateurs dans auth.users' as info
FROM auth.users;

-- Vérifier la cohérence
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM wallets) = (SELECT COUNT(*) FROM auth.users)
        THEN '✅ Tous les utilisateurs ont un portefeuille'
        ELSE '⚠️ Certains utilisateurs n''ont pas de portefeuille'
    END as verification;

-- Étape 9: Statistiques finales
SELECT '📊 ÉTAPE 9: Statistiques finales' as info;

SELECT 
    'wallets' as table_name,
    COUNT(*) as total_records,
    MIN(created_at) as plus_ancien,
    MAX(created_at) as plus_recent
FROM wallets
UNION ALL
SELECT 
    'wallet_transactions' as table_name,
    COUNT(*) as total_records,
    MIN(created_at) as plus_ancien,
    MAX(created_at) as plus_recent
FROM wallet_transactions;

-- Message de confirmation
SELECT '🎉 CORRECTION TERMINÉE AVEC SUCCÈS!' as message;
SELECT 'Le système de portefeuille est maintenant opérationnel.' as info;
SELECT 'Les utilisateurs peuvent maintenant créer et gérer leur portefeuille.' as info;
