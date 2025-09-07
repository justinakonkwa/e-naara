-- =====================================================
-- 🔍 DIAGNOSTIC SIMPLE DE LA CONFIRMATION DE LIVRAISON
-- =====================================================

-- 1. Vérifier si la commande existe
SELECT 
    'Verification de la commande:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    driver_id,
    delivered_at,
    updated_at
FROM orders 
WHERE id = '862d6aae-9bb1-4e48-802f-b5024040f031'::UUID;

-- 2. Vérifier toutes les commandes avec le code court
SELECT 
    'Toutes les commandes avec code court 862d6aae:' as message,
    id,
    LEFT(id::TEXT, 8) as short_code,
    status,
    driver_id,
    delivered_at,
    updated_at
FROM orders 
WHERE LEFT(id::TEXT, 8) = '862d6aae'
ORDER BY created_at DESC;

-- 3. Tester la fonction simple_confirm_delivery
SELECT 'Test de simple_confirm_delivery:' as test_message;
SELECT simple_confirm_delivery('862d6aae-9bb1-4e48-802f-b5024040f031'::UUID) as result;

-- 4. Vérifier le statut après test
SELECT 
    'Statut apres test:' as message,
    id,
    status,
    delivered_at,
    updated_at
FROM orders 
WHERE id = '862d6aae-9bb1-4e48-802f-b5024040f031'::UUID;

-- 5. Test de mise à jour directe
SELECT 'Test de mise a jour directe:' as test_message;

UPDATE orders 
SET 
    status = 'delivered',
    updated_at = NOW(),
    delivered_at = NOW()
WHERE id = '862d6aae-9bb1-4e48-802f-b5024040f031'::UUID;

-- 6. Vérifier le résultat de la mise à jour directe
SELECT 
    'Resultat de la mise a jour directe:' as message,
    id,
    status,
    delivered_at,
    updated_at
FROM orders 
WHERE id = '862d6aae-9bb1-4e48-802f-b5024040f031'::UUID;

-- 7. Compter les commandes livrées
SELECT 
    'Nombre de commandes livrees:' as message,
    COUNT(*) as delivered_count
FROM orders 
WHERE status = 'delivered';

-- 8. Message de fin
SELECT 'Diagnostic termine avec succes' as result;

