-- =====================================================
-- 🧹 NETTOYAGE DU SYSTÈME DE GESTION DES QUANTITÉS
-- =====================================================

-- ATTENTION: Ce script supprime tous les éléments du système de gestion des quantités
-- Utilisez-le seulement si vous voulez recommencer à zéro

-- Supprimer les triggers existants
DROP TRIGGER IF EXISTS update_product_quantity_trigger ON orders;
DROP TRIGGER IF EXISTS restore_product_quantity_trigger ON orders;
DROP TRIGGER IF EXISTS check_product_availability_trigger ON orders;

-- Supprimer les fonctions
DROP FUNCTION IF EXISTS update_product_quantity_on_sale();
DROP FUNCTION IF EXISTS restore_product_quantity_on_cancel();
DROP FUNCTION IF EXISTS check_product_availability();

-- Supprimer les index
DROP INDEX IF EXISTS idx_products_quantity;
DROP INDEX IF EXISTS idx_products_available;

-- Message de confirmation
SELECT '🧹 Nettoyage du système de gestion des quantités terminé !' as message;
