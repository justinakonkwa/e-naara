-- =====================================================
-- SCRIPT D'INSERTION DES PRODUITS D'EXEMPLE
-- À exécuter APRÈS le script de création des tables
-- =====================================================

-- Insérer des produits d'exemple
INSERT INTO products (id, name, description, price, original_price, image_url, images, category, subcategory, brand, rating, review_count, is_available, stock_quantity, is_featured, tags, specifications, created_at) VALUES
(
    '1',
    'iPhone 15 Pro Max',
    'Le smartphone le plus avancé d''Apple avec puce A17 Pro, appareil photo professionnel et écran Super Retina XDR de 6,7 pouces.',
    1229.99,
    1329.99,
    'https://pixabay.com/get/g8dba1b6a78ac86cabb303123616dad817f66e8dbc972cdfdc3dba26741ffe428e0fe9599b9a73aedc82e1d8a8d130141e656ea0a546ad6224cb33fb0602cdfbf_1280.jpg',
    ARRAY[
        'https://pixabay.com/get/g8dba1b6a78ac86cabb303123616dad817f66e8dbc972cdfdc3dba26741ffe428e0fe9599b9a73aedc82e1d8a8d130141e656ea0a546ad6224cb33fb0602cdfbf_1280.jpg',
        'https://pixabay.com/get/g8dba1b6a78ac86cabb303123616dad817f66e8dbc972cdfdc3dba26741ffe428e0fe9599b9a73aedc82e1d8a8d130141e656ea0a546ad6224cb33fb0602cdfbf_1280.jpg',
        'https://pixabay.com/get/g8dba1b6a78ac86cabb303123616dad817f66e8dbc972cdfdc3dba26741ffe428e0fe9599b9a73aedc82e1d8a8d130141e656ea0a546ad6224cb33fb0602cdfbf_1280.jpg'
    ],
    'electronics',
    'Smartphones',
    'Apple',
    4.8,
    1247,
    true,
    45,
    true,
    ARRAY['premium', 'nouveau', 'populaire'],
    '{"Écran": "6,7\" Super Retina XDR", "Processeur": "A17 Pro", "Stockage": "256 Go", "Caméra": "48MP + 12MP + 12MP", "Batterie": "4422 mAh"}',
    NOW() - INTERVAL '5 days'
),
(
    '2',
    'Sony WH-1000XM5',
    'Casque sans fil à réduction de bruit de qualité professionnelle avec audio haute résolution et autonomie de 30 heures.',
    349.99,
    399.99,
    'https://pixabay.com/get/gba08d38a0345d4f6b7dc8eca866d2977203812c426577698e30a0a6a21c2d58925e89271101627cb2f88d7974a3d205e656af1023473c65ff14a12f794aa9e58_1280.jpg',
    ARRAY[
        'https://pixabay.com/get/gba08d38a0345d4f6b7dc8eca866d2977203812c426577698e30a0a6a21c2d58925e89271101627cb2f88d7974a3d205e656af1023473c65ff14a12f794aa9e58_1280.jpg',
        'https://pixabay.com/get/gba08d38a0345d4f6b7dc8eca866d2977203812c426577698e30a0a6a21c2d58925e89271101627cb2f88d7974a3d205e656af1023473c65ff14a12f794aa9e58_1280.jpg',
        'https://pixabay.com/get/gba08d38a0345d4f6b7dc8eca866d2977203812c426577698e30a0a6a21c2d58925e89271101627cb2f88d7974a3d205e656af1023473c65ff14a12f794aa9e58_1280.jpg'
    ],
    'electronics',
    'Audio',
    'Sony',
    4.7,
    892,
    true,
    23,
    true,
    ARRAY['audio', 'sans-fil', 'réduction bruit'],
    '{"Type": "Supra-auriculaire", "Connectivité": "Bluetooth 5.2, USB-C", "Autonomie": "30 heures", "Réduction de bruit": "Active", "Poids": "250g"}',
    NOW() - INTERVAL '12 days'
),
(
    '3',
    'Apple Watch Series 9',
    'Montre connectée avec écran Always-On Retina, suivi santé avancé et nouvelles fonctionnalités d''assistance.',
    449.99,
    449.99,
    'https://pixabay.com/get/g1f41e703b9a3d90ea7923cd46702808c754237381203e2b7b4bb3462502de8438e14e1ecc77d220ed77f2daf5310da21088d0bcdbeb0b33de9516ddc0bbd8594_1280.jpg',
    ARRAY[
        'https://pixabay.com/get/g1f41e703b9a3d90ea7923cd46702808c754237381203e2b7b4bb3462502de8438e14e1ecc77d220ed77f2daf5310da21088d0bcdbeb0b33de9516ddc0bbd8594_1280.jpg',
        'https://pixabay.com/get/g1f41e703b9a3d90ea7923cd46702808c754237381203e2b7b4bb3462502de8438e14e1ecc77d220ed77f2daf5310da21088d0bcdbeb0b33de9516ddc0bbd8594_1280.jpg',
        'https://pixabay.com/get/g1f41e703b9a3d90ea7923cd46702808c754237381203e2b7b4bb3462502de8438e14e1ecc77d220ed77f2daf5310da21088d0bcdbeb0b33de9516ddc0bbd8594_1280.jpg'
    ],
    'fashion',
    'Montres',
    'Apple',
    4.6,
    567,
    true,
    67,
    false,
    ARRAY['connectée', 'santé', 'fitness'],
    '{"Écran": "1,9\" Retina LTPO OLED", "Processeur": "S9 SiP", "Étanchéité": "50 mètres", "GPS": "Intégré", "Capteurs": "ECG, SpO2, Température"}',
    NOW() - INTERVAL '8 days'
),
(
    '4',
    'Nike Air Max 270',
    'Baskets lifestyle avec amorti Air Max visible et design moderne pour un confort optimal toute la journée.',
    129.99,
    159.99,
    'https://pixabay.com/get/g9d136a3f18536100abce1a030758e732504b06bc7f8389ba8e7ba0f4869b9b1006c799575da8dfa5eaa5c532c654ab5b7fe301b4833f7e166d861938a026caeb_1280.jpg',
    ARRAY[
        'https://pixabay.com/get/g9d136a3f18536100abce1a030758e732504b06bc7f8389ba8e7ba0f4869b9b1006c799575da8dfa5eaa5c532c654ab5b7fe301b4833f7e166d861938a026caeb_1280.jpg',
        'https://pixabay.com/get/g9d136a3f18536100abce1a030758e732504b06bc7f8389ba8e7ba0f4869b9b1006c799575da8dfa5eaa5c532c654ab5b7fe301b4833f7e166d861938a026caeb_1280.jpg',
        'https://pixabay.com/get/g9d136a3f18536100abce1a030758e732504b06bc7f8389ba8e7ba0f4869b9b1006c799575da8dfa5eaa5c532c654ab5b7fe301b4833f7e166d861938a026caeb_1280.jpg'
    ],
    'fashion',
    'Chaussures',
    'Nike',
    4.5,
    1203,
    true,
    156,
    true,
    ARRAY['sport', 'lifestyle', 'confort'],
    '{"Type": "Lifestyle/Running", "Semelle": "Air Max", "Matériau": "Mesh + Synthétique", "Couleurs": "Noir, Blanc, Gris", "Genre": "Unisexe"}',
    NOW() - INTERVAL '3 days'
),
(
    '5',
    'Ray-Ban Aviator Classic',
    'Lunettes de soleil iconiques avec verres en cristal et monture métallique. Protection UV 100%.',
    149.99,
    179.99,
    'https://pixabay.com/get/g41a864bb0e17886aeeb097054246fa7cb131f3fd0d0c3b50d95065cf3c52537b2b3275561aeb0b9738bb2294135ab0203c6827c7ee5ea6f8a8921f3a84463950_1280.jpg',
    ARRAY[
        'https://pixabay.com/get/g41a864bb0e17886aeeb097054246fa7cb131f3fd0d0c3b50d95065cf3c52537b2b3275561aeb0b9738bb2294135ab0203c6827c7ee5ea6f8a8921f3a84463950_1280.jpg',
        'https://pixabay.com/get/g41a864bb0e17886aeeb097054246fa7cb131f3fd0d0c3b50d95065cf3c52537b2b3275561aeb0b9738bb2294135ab0203c6827c7ee5ea6f8a8921f3a84463950_1280.jpg',
        'https://pixabay.com/get/g41a864bb0e17886aeeb097054246fa7cb131f3fd0d0c3b50d95065cf3c52537b2b3275561aeb0b9738bb2294135ab0203c6827c7ee5ea6f8a8921f3a84463950_1280.jpg'
    ],
    'fashion',
    'Accessoires',
    'Ray-Ban',
    4.7,
    789,
    true,
    89,
    false,
    ARRAY['classique', 'protection UV', 'style'],
    '{"Forme": "Aviator", "Verres": "Cristal G-15", "Monture": "Métal doré", "Protection": "UV 100%", "Taille": "58mm"}',
    NOW() - INTERVAL '15 days'
),
(
    '6',
    'MacBook Air M2',
    'Ordinateur portable ultra-fin avec puce M2, écran Liquid Retina 13,6" et autonomie exceptionnelle de 18 heures.',
    1199.99,
    1299.99,
    'https://pixabay.com/get/g0f0c57981e06003a056fc0adee98a4a46ee836f85aac79831dbe01630bdbafba72507c455e502b234d28026c6848f93be8adfbcf2204d96240ad9c362f92cc85_1280.jpg',
    ARRAY[
        'https://pixabay.com/get/g0f0c57981e06003a056fc0adee98a4a46ee836f85aac79831dbe01630bdbafba72507c455e502b234d28026c6848f93be8adfbcf2204d96240ad9c362f92cc85_1280.jpg',
        'https://pixabay.com/get/g0f0c57981e06003a056fc0adee98a4a46ee836f85aac79831dbe01630bdbafba72507c455e502b234d28026c6848f93be8adfbcf2204d96240ad9c362f92cc85_1280.jpg',
        'https://pixabay.com/get/g0f0c57981e06003a056fc0adee98a4a46ee836f85aac79831dbe01630bdbafba72507c455e502b234d28026c6848f93be8adfbcf2204d96240ad9c362f92cc85_1280.jpg'
    ],
    'electronics',
    'Ordinateurs',
    'Apple',
    4.8,
    445,
    true,
    12,
    true,
    ARRAY['ultrabook', 'performance', 'autonomie'],
    '{"Processeur": "Apple M2", "Écran": "13,6\" Liquid Retina", "Mémoire": "8 Go RAM unifiée", "Stockage": "256 Go SSD", "Autonomie": "18 heures"}',
    NOW() - INTERVAL '7 days'
),
(
    '7',
    'PlayStation 5',
    'Console de jeux nouvelle génération avec processeur AMD Zen 2 et GPU RDNA 2 pour une expérience gaming 4K.',
    549.99,
    549.99,
    'https://pixabay.com/get/ge5384d8c87b5217bbcf516a89d50a93724cd4868798856de2cf93aab1e4505c5a1d4a2c3e3c7547163c2fa8e1273f840fea8064c0e0d4419649cd93ae3a710d1_1280.jpg',
    ARRAY[
        'https://pixabay.com/get/ge5384d8c87b5217bbcf516a89d50a93724cd4868798856de2cf93aab1e4505c5a1d4a2c3e3c7547163c2fa8e1273f840fea8064c0e0d4419649cd93ae3a710d1_1280.jpg',
        'https://pixabay.com/get/ge5384d8c87b5217bbcf516a89d50a93724cd4868798856de2cf93aab1e4505c5a1d4a2c3e3c7547163c2fa8e1273f840fea8064c0e0d4419649cd93ae3a710d1_1280.jpg',
        'https://pixabay.com/get/ge5384d8c87b5217bbcf516a89d50a93724cd4868798856de2cf93aab1e4505c5a1d4a2c3e3c7547163c2fa8e1273f840fea8064c0e0d4419649cd93ae3a710d1_1280.jpg'
    ],
    'electronics',
    'Gaming',
    'Sony',
    4.9,
    2156,
    false,
    0,
    true,
    ARRAY['gaming', 'nouvelle génération', '4K'],
    '{"Processeur": "AMD Zen 2 8-core", "GPU": "AMD RDNA 2", "Mémoire": "16 Go GDDR6", "Stockage": "825 Go SSD", "Résolution": "4K UHD"}',
    NOW() - INTERVAL '20 days'
),
(
    '8',
    'Sac à main Hermès Style',
    'Sac à main élégant en cuir véritable avec finitions premium et design intemporel pour toutes les occasions.',
    299.99,
    349.99,
    'https://pixabay.com/get/g20d9f60ccf324219d465bfa82d1af9b02786592d6eef675d9aff18b87627d772a382c0c3eede3a99f3673d35e99e8c08ad70fe8eb5f83202f3841e0e4a5163e7_1280.jpg',
    ARRAY[
        'https://pixabay.com/get/g20d9f60ccf324219d465bfa82d1af9b02786592d6eef675d9aff18b87627d772a382c0c3eede3a99f3673d35e99e8c08ad70fe8eb5f83202f3841e0e4a5163e7_1280.jpg',
        'https://pixabay.com/get/g20d9f60ccf324219d465bfa82d1af9b02786592d6eef675d9aff18b87627d772a382c0c3eede3a99f3673d35e99e8c08ad70fe8eb5f83202f3841e0e4a5163e7_1280.jpg',
        'https://pixabay.com/get/g20d9f60ccf324219d465bfa82d1af9b02786592d6eef675d9aff18b87627d772a382c0c3eede3a99f3673d35e99e8c08ad70fe8eb5f83202f3841e0e4a5163e7_1280.jpg'
    ],
    'fashion',
    'Accessoires',
    'Premium Collection',
    4.4,
    234,
    true,
    45,
    false,
    ARRAY['luxe', 'cuir', 'élégant'],
    '{"Matériau": "Cuir véritable", "Dimensions": "30x25x12 cm", "Couleurs": "Noir, Marron, Beige", "Fermeture": "Fermeture éclair + bouton", "Poches": "3 intérieures, 1 extérieure"}',
    NOW() - INTERVAL '10 days'
)
ON CONFLICT (id) DO NOTHING;

-- Insérer quelques avis d'exemple
INSERT INTO reviews (product_id, user_id, user_name, rating, comment, is_verified_purchase, created_at) VALUES
('1', '00000000-0000-0000-0000-000000000001', 'Thomas L.', 5.0, 'Excellent smartphone ! La qualité de l''appareil photo est impressionnante et la batterie tient largement la journée. Je recommande vivement.', true, NOW() - INTERVAL '3 days'),
('1', '00000000-0000-0000-0000-000000000002', 'Sophie M.', 4.0, 'Très bon téléphone, design premium et performances au top. Seul bémol : le prix qui reste élevé mais justifié par la qualité.', true, NOW() - INTERVAL '7 days'),
('2', '00000000-0000-0000-0000-000000000003', 'Alexandre D.', 5.0, 'Le meilleur casque que j''ai jamais eu ! La réduction de bruit est fantastique et le confort d''écoute exceptionnel.', true, NOW() - INTERVAL '5 days'),
('4', '00000000-0000-0000-0000-000000000004', 'Emma R.', 4.5, 'Très confortables pour la course à pied. Le design est moderne et les couleurs sont belles.', true, NOW() - INTERVAL '2 days'),
('6', '00000000-0000-0000-0000-000000000005', 'Pierre L.', 5.0, 'Performance exceptionnelle, autonomie incroyable. Parfait pour le travail et les loisirs.', true, NOW() - INTERVAL '1 day')
ON CONFLICT (product_id, user_id) DO NOTHING;

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ 8 produits d''exemple ont été insérés !';
    RAISE NOTICE '✅ 5 avis clients ont été ajoutés !';
    RAISE NOTICE '🎉 Votre catalogue ShopFlow est maintenant prêt !';
END $$;
