-- Ajouter les colonnes GPS pour les coordonnées de livraison
ALTER TABLE orders 
ADD COLUMN shipping_latitude DOUBLE PRECISION,
ADD COLUMN shipping_longitude DOUBLE PRECISION;

-- Créer un index pour optimiser les requêtes géospatiales
CREATE INDEX idx_orders_shipping_coordinates 
ON orders(shipping_latitude, shipping_longitude);

-- Ajouter un commentaire pour documenter les nouvelles colonnes
COMMENT ON COLUMN orders.shipping_latitude IS 'Latitude de l''adresse de livraison';
COMMENT ON COLUMN orders.shipping_longitude IS 'Longitude de l''adresse de livraison';

-- Mettre à jour les RLS policies pour inclure les nouvelles colonnes
-- (Les policies existantes devraient déjà couvrir ces colonnes car elles utilisent SELECT *)

-- Exemple de mise à jour d'une commande existante avec des coordonnées GPS
-- UPDATE orders 
-- SET shipping_latitude = 48.8566, shipping_longitude = 2.3522 
-- WHERE id = 'your-order-id';


