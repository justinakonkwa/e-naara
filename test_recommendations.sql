-- Script de test pour vérifier les tables de recommandation
-- À exécuter après avoir créé les tables

-- 1. Vérifier que les tables existent
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('search_history', 'product_views', 'product_recommendations');

-- 2. Vérifier la structure des tables
\d search_history;
\d product_views;
\d product_recommendations;

-- 3. Vérifier les politiques RLS
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('search_history', 'product_views', 'product_recommendations');

-- 4. Vérifier les index
SELECT indexname, tablename, indexdef 
FROM pg_indexes 
WHERE tablename IN ('search_history', 'product_views', 'product_recommendations');

-- 5. Test d'insertion (à exécuter avec un utilisateur connecté)
-- INSERT INTO search_history (user_id, query, result_count) 
-- VALUES (auth.uid(), 'test query', 5);

-- INSERT INTO product_views (user_id, product_id, view_duration) 
-- VALUES (auth.uid(), 'product-1', 30);

-- INSERT INTO product_recommendations (user_id, product_id, recommended_product_id, score, reason) 
-- VALUES (auth.uid(), 'product-1', 'product-2', 0.85, 'category_similarity');
