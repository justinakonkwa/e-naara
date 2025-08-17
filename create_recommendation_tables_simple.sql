-- Table pour l'historique de recherche
CREATE TABLE IF NOT EXISTS search_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    query TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    result_count INTEGER DEFAULT 0
);

-- Table pour l'historique de consultation de produits
CREATE TABLE IF NOT EXISTS product_views (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id TEXT REFERENCES products(id) ON DELETE CASCADE,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    view_duration INTEGER DEFAULT 0
);

-- Table pour les recommandations de produits
CREATE TABLE IF NOT EXISTS product_recommendations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id TEXT REFERENCES products(id) ON DELETE CASCADE,
    recommended_product_id TEXT REFERENCES products(id) ON DELETE CASCADE,
    score DECIMAL(5,4) DEFAULT 0.0,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_search_history_user_id ON search_history(user_id);
CREATE INDEX IF NOT EXISTS idx_search_history_created_at ON search_history(created_at);
CREATE INDEX IF NOT EXISTS idx_product_views_user_id ON product_views(user_id);
CREATE INDEX IF NOT EXISTS idx_product_views_product_id ON product_views(product_id);
CREATE INDEX IF NOT EXISTS idx_product_views_viewed_at ON product_views(viewed_at);
CREATE INDEX IF NOT EXISTS idx_product_recommendations_user_id ON product_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_product_recommendations_score ON product_recommendations(score);

-- RLS (Row Level Security)
ALTER TABLE search_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_recommendations ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour search_history
CREATE POLICY "Users can view their own search history" ON search_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own search history" ON search_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own search history" ON search_history
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques RLS pour product_views
CREATE POLICY "Users can view their own product views" ON product_views
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own product views" ON product_views
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politiques RLS pour product_recommendations
CREATE POLICY "Users can view their own recommendations" ON product_recommendations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own recommendations" ON product_recommendations
    FOR INSERT WITH CHECK (auth.uid() = user_id);
