-- =====================================================
-- 🧹 SCRIPT DE NETTOYAGE DU SYSTÈME DE PORTEFEUILLE
-- =====================================================

-- ATTENTION: Ce script supprime tous les éléments du système de portefeuille
-- Utilisez-le seulement si vous voulez recommencer à zéro

-- Supprimer les triggers existants
DROP TRIGGER IF EXISTS update_wallets_updated_at ON wallets;
DROP TRIGGER IF EXISTS create_wallet_for_user_trigger ON users;
DROP TRIGGER IF EXISTS add_money_to_user_wallet_trigger ON orders;

-- Supprimer les fonctions
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP FUNCTION IF EXISTS create_wallet_for_user();
DROP FUNCTION IF EXISTS add_money_to_user_wallet();

-- Supprimer les politiques RLS
DROP POLICY IF EXISTS "Users can view their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can update their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can insert their own wallet" ON wallets;

DROP POLICY IF EXISTS "Users can view their own wallet transactions" ON wallet_transactions;
DROP POLICY IF EXISTS "Users can insert their own wallet transactions" ON wallet_transactions;

-- Supprimer les index
DROP INDEX IF EXISTS idx_wallets_user_id;
DROP INDEX IF EXISTS idx_wallet_transactions_wallet_id;
DROP INDEX IF EXISTS idx_wallet_transactions_created_at;
DROP INDEX IF EXISTS idx_wallet_transactions_type;
DROP INDEX IF EXISTS idx_wallet_transactions_status;
DROP INDEX IF EXISTS idx_products_seller_id;

-- Supprimer les tables (ATTENTION: cela supprime toutes les données)
DROP TABLE IF EXISTS wallet_transactions CASCADE;
DROP TABLE IF EXISTS wallets CASCADE;

-- Supprimer la colonne seller_id de la table products (si elle existe)
ALTER TABLE products DROP COLUMN IF EXISTS seller_id;

-- Message de confirmation
SELECT '🧹 Nettoyage terminé ! Vous pouvez maintenant exécuter setup_wallet_tables.sql' as message;
