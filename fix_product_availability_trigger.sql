-- Script pour corriger la fonction check_product_availability
-- Le problème est que la fonction vérifie quantity > 0 mais pas quantity >= NEW.quantity

-- Supprimer l'ancien trigger
DROP TRIGGER IF EXISTS check_product_availability_trigger ON orders;

-- Recréer la fonction avec la logique corrigée
CREATE OR REPLACE FUNCTION check_product_availability()
RETURNS TRIGGER AS $$
DECLARE
    product_record RECORD;
BEGIN
    -- Récupérer les informations du produit
    SELECT * INTO product_record
    FROM products 
    WHERE id = NEW.product_id;
    
    -- Vérifier si le produit existe
    IF product_record.id IS NULL THEN
        RAISE EXCEPTION 'Le produit % n''existe pas', NEW.product_id;
    END IF;
    
    -- Vérifier si le produit est disponible
    IF NOT product_record.is_available THEN
        RAISE EXCEPTION 'Le produit % n''est pas disponible (is_available = false)', NEW.product_id;
    END IF;
    
    -- Vérifier si la quantité en stock est suffisante
    IF product_record.quantity < NEW.quantity THEN
        RAISE EXCEPTION 'Quantité insuffisante pour le produit %. Stock disponible: %, Quantité demandée: %', 
            NEW.product_id, product_record.quantity, NEW.quantity;
    END IF;
    
    -- Vérifier que la quantité demandée est positive
    IF NEW.quantity <= 0 THEN
        RAISE EXCEPTION 'La quantité demandée doit être positive (actuelle: %)', NEW.quantity;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Recréer le trigger
CREATE TRIGGER check_product_availability_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION check_product_availability();

-- Tester la fonction avec le produit problématique
DO $$
DECLARE
    product_record RECORD;
    product_id TEXT := '1755205022966';
    requested_quantity INTEGER := 1;
BEGIN
    -- Récupérer les informations du produit
    SELECT * INTO product_record 
    FROM products 
    WHERE id = product_id;
    
    -- Afficher les informations pour debug
    RAISE NOTICE '=== DIAGNOSTIC DU PRODUIT ===';
    RAISE NOTICE 'ID: %', product_record.id;
    RAISE NOTICE 'Nom: %', product_record.name;
    RAISE NOTICE 'Prix: %', product_record.price;
    RAISE NOTICE 'Quantité en stock: %', product_record.quantity;
    RAISE NOTICE 'Disponible: %', product_record.is_available;
    RAISE NOTICE 'Vendeur: %', product_record.seller_id;
    RAISE NOTICE 'Quantité demandée: %', requested_quantity;
    
    -- Tester la logique de la fonction
    IF product_record.id IS NULL THEN
        RAISE NOTICE '❌ ERREUR: Le produit % n''existe pas', product_id;
    ELSIF NOT product_record.is_available THEN
        RAISE NOTICE '❌ ERREUR: Le produit % n''est pas disponible (is_available = false)', product_id;
    ELSIF product_record.quantity < requested_quantity THEN
        RAISE NOTICE '❌ ERREUR: Quantité insuffisante. Stock: %, Demandé: %', 
            product_record.quantity, requested_quantity;
    ELSE
        RAISE NOTICE '✅ SUCCÈS: Le produit % est disponible pour la commande!', product_id;
    END IF;
END $$;

-- Vérifier que le trigger a été recréé
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
AND trigger_name = 'check_product_availability_trigger';

-- Message de confirmation
SELECT '🔧 Trigger check_product_availability corrigé avec succès!' as message;
