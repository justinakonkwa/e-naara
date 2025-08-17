-- Création de la table des sous-catégories
CREATE TABLE IF NOT EXISTS subcategories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category_id VARCHAR(50) NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(name, category_id)
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_subcategories_category_id ON subcategories(category_id);
CREATE INDEX IF NOT EXISTS idx_subcategories_created_by ON subcategories(created_by);

-- RLS (Row Level Security) pour les sous-catégories
ALTER TABLE subcategories ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre la lecture de toutes les sous-catégories
CREATE POLICY "Allow read access to all subcategories" ON subcategories
    FOR SELECT USING (true);

-- Politique pour permettre la création de sous-catégories par les utilisateurs authentifiés
CREATE POLICY "Allow authenticated users to create subcategories" ON subcategories
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Politique pour permettre la mise à jour de ses propres sous-catégories
CREATE POLICY "Allow users to update their own subcategories" ON subcategories
    FOR UPDATE USING (auth.uid() = created_by);

-- Politique pour permettre la suppression de ses propres sous-catégories
CREATE POLICY "Allow users to delete their own subcategories" ON subcategories
    FOR DELETE USING (auth.uid() = created_by);

-- Fonction pour mettre à jour le timestamp
CREATE OR REPLACE FUNCTION update_subcategories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour automatiquement le timestamp
CREATE TRIGGER update_subcategories_updated_at
    BEFORE UPDATE ON subcategories
    FOR EACH ROW
    EXECUTE FUNCTION update_subcategories_updated_at();

-- Insertion des sous-catégories par défaut
INSERT INTO subcategories (name, category_id, created_by) VALUES
-- Électronique
('Smartphones', 'electronics', NULL),
('Ordinateurs', 'electronics', NULL),
('Audio', 'electronics', NULL),
('Gaming', 'electronics', NULL),
('Accessoires', 'electronics', NULL),

-- Mode
('Vêtements', 'fashion', NULL),
('Chaussures', 'fashion', NULL),
('Accessoires', 'fashion', NULL),
('Montres', 'fashion', NULL),
('Bijoux', 'fashion', NULL),

-- Maison
('Meubles', 'home', NULL),
('Décoration', 'home', NULL),
('Électroménager', 'home', NULL),
('Jardin', 'home', NULL),
('Bricolage', 'home', NULL),

-- Sports
('Fitness', 'sports', NULL),
('Outdoor', 'sports', NULL),
('Vêtements sport', 'sports', NULL),
('Équipements', 'sports', NULL),
('Vélos', 'sports', NULL),

-- Beauté
('Maquillage', 'beauty', NULL),
('Soins', 'beauty', NULL),
('Parfums', 'beauty', NULL),
('Cheveux', 'beauty', NULL),
('Bien-être', 'beauty', NULL),

-- Livres
('Romans', 'books', NULL),
('Éducation', 'books', NULL),
('BD & Manga', 'books', NULL),
('Cuisine', 'books', NULL),
('Voyage', 'books', NULL)
ON CONFLICT (name, category_id) DO NOTHING;

-- Commentaires
COMMENT ON TABLE subcategories IS 'Table pour stocker les sous-catégories de produits';
COMMENT ON COLUMN subcategories.id IS 'Identifiant unique de la sous-catégorie';
COMMENT ON COLUMN subcategories.name IS 'Nom de la sous-catégorie';
COMMENT ON COLUMN subcategories.category_id IS 'ID de la catégorie parente';
COMMENT ON COLUMN subcategories.created_by IS 'ID de l''utilisateur qui a créé la sous-catégorie';
COMMENT ON COLUMN subcategories.created_at IS 'Date de création';
COMMENT ON COLUMN subcategories.updated_at IS 'Date de dernière modification';
