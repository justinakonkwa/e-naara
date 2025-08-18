-- =====================================================
-- CONFIGURATION DU STORAGE POUR LES IMAGES DE PRODUITS
-- À exécuter dans l'éditeur SQL de Supabase
-- =====================================================

-- Créer le bucket pour les images de produits
INSERT INTO storage.buckets (id, name, public) 
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- Politique pour permettre l'upload d'images aux utilisateurs authentifiés
CREATE POLICY "Authenticated users can upload product images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'product-images' 
        AND auth.role() = 'authenticated'
    );

-- Politique pour permettre la lecture publique des images
CREATE POLICY "Anyone can view product images" ON storage.objects
    FOR SELECT USING (bucket_id = 'product-images');

-- Politique pour permettre la mise à jour des images aux utilisateurs authentifiés
CREATE POLICY "Authenticated users can update product images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'product-images' 
        AND auth.role() = 'authenticated'
    );

-- Politique pour permettre la suppression des images aux utilisateurs authentifiés
CREATE POLICY "Authenticated users can delete product images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'product-images' 
        AND auth.role() = 'authenticated'
    );

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Bucket product-images créé avec succès !';
    RAISE NOTICE '✅ Politiques de storage configurées';
    RAISE NOTICE '✅ Les utilisateurs authentifiés peuvent uploader des images';
    RAISE NOTICE '✅ Les images sont accessibles publiquement';
END $$;





