-- =====================================================
-- 🔧 CORRECTION DE LA CONTRAINTE ORDERS_STATUS_VALID
-- =====================================================

-- Ce script corrige la contrainte orders_status_valid pour inclure tous les statuts
-- nécessaires au système de livraison

-- Étape 1: Vérifier la contrainte actuelle
SELECT 'Contrainte actuelle orders_status_valid:' as info;

SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_name = 'orders_status_valid';

-- Étape 2: Vérifier les statuts actuellement utilisés
SELECT 'Statuts actuellement utilisés dans la table orders:' as info;

SELECT 
    status,
    COUNT(*) as count
FROM orders 
GROUP BY status 
ORDER BY count DESC;

-- Étape 3: Supprimer l'ancienne contrainte
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'orders_status_valid'
    ) THEN
        ALTER TABLE orders DROP CONSTRAINT orders_status_valid;
        RAISE NOTICE 'Ancienne contrainte orders_status_valid supprimée';
    ELSE
        RAISE NOTICE 'Contrainte orders_status_valid n''existe pas';
    END IF;
END $$;

-- Étape 4: Créer la nouvelle contrainte avec tous les statuts nécessaires
ALTER TABLE orders ADD CONSTRAINT orders_status_valid 
CHECK (status IN (
    'pending',      -- En attente de confirmation
    'confirmed',    -- Confirmée, prête pour livraison
    'assigned',     -- Assignée à un livreur
    'picked_up',    -- Récupérée par le livreur
    'in_transit',   -- En cours de livraison
    'delivered',    -- Livrée avec succès
    'cancelled',    -- Annulée
    'refunded'      -- Remboursée
));

-- Étape 5: Vérifier la nouvelle contrainte
SELECT 'Nouvelle contrainte orders_status_valid:' as info;

SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_name = 'orders_status_valid';

-- Étape 6: Vérifier que tous les statuts existants sont valides
SELECT 'Vérification des statuts existants:' as info;

SELECT 
    status,
    COUNT(*) as count,
    CASE 
        WHEN status IN ('pending', 'confirmed', 'assigned', 'picked_up', 'in_transit', 'delivered', 'cancelled', 'refunded') 
        THEN '✅ VALIDE' 
        ELSE '❌ INVALIDE' 
    END as validation
FROM orders 
GROUP BY status 
ORDER BY count DESC;

-- Étape 7: Mettre à jour les statuts invalides si nécessaire
DO $$ 
DECLARE
    invalid_status_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO invalid_status_count
    FROM orders 
    WHERE status NOT IN ('pending', 'confirmed', 'assigned', 'picked_up', 'in_transit', 'delivered', 'cancelled', 'refunded');
    
    IF invalid_status_count > 0 THEN
        RAISE NOTICE 'Mise à jour de % commandes avec des statuts invalides vers ''pending''', invalid_status_count;
        
        UPDATE orders 
        SET status = 'pending', updated_at = NOW()
        WHERE status NOT IN ('pending', 'confirmed', 'assigned', 'picked_up', 'in_transit', 'delivered', 'cancelled', 'refunded');
        
        RAISE NOTICE 'Statuts invalides mis à jour avec succès';
    ELSE
        RAISE NOTICE 'Aucun statut invalide trouvé';
    END IF;
END $$;

-- Étape 8: Statistiques finales
SELECT 'Statistiques finales des statuts:' as info;

SELECT 
    status,
    COUNT(*) as count,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders))::DECIMAL(5,2), 2) as percentage
FROM orders 
GROUP BY status 
ORDER BY count DESC;

-- Étape 9: Test de la contrainte
DO $$ 
BEGIN
    -- Test avec un statut valide
    BEGIN
        UPDATE orders SET status = 'assigned' WHERE id = (SELECT id FROM orders LIMIT 1);
        RAISE NOTICE '✅ Test avec statut valide réussi';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '❌ Test avec statut valide échoué';
    END;
    
    -- Test avec un statut invalide (devrait échouer)
    BEGIN
        UPDATE orders SET status = 'invalid_status' WHERE id = (SELECT id FROM orders LIMIT 1);
        RAISE NOTICE '❌ Test avec statut invalide a réussi (ne devrait pas)';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✅ Test avec statut invalide a échoué comme attendu';
    END;
END $$;

-- Message de confirmation
SELECT '✅ Contrainte orders_status_valid corrigée avec succès!' as message;
