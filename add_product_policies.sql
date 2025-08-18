-- =====================================================
-- AJOUT DES POLITIQUES RLS POUR LA CRÉATION DE PRODUITS
-- À exécuter dans l'éditeur SQL de Supabase
-- =====================================================

-- Activer RLS sur la table products si ce n'est pas déjà fait
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre aux utilisateurs authentifiés de créer des produits
CREATE POLICY "Authenticated users can create products" ON products
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Politique pour permettre aux utilisateurs authentifiés de modifier leurs produits
-- (optionnel, pour une future fonctionnalité d'édition)
CREATE POLICY "Authenticated users can update products" ON products
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Politique pour permettre aux utilisateurs authentifiés de supprimer leurs produits
-- (optionnel, pour une future fonctionnalité de suppression)
CREATE POLICY "Authenticated users can delete products" ON products
    FOR DELETE USING (auth.role() = 'authenticated');

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Politiques RLS pour les produits ajoutées avec succès !';
    RAISE NOTICE '✅ Les utilisateurs authentifiés peuvent maintenant créer des produits';
END $$;





