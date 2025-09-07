-- Script de correction pour le trigger check_product_availability (VERSION CORRIGÉE)
-- À exécuter dans l'interface Supabase SQL Editor

-- 1. Supprimer l'ancien trigger
DROP TRIGGER IF EXISTS check_product_availability_trigger ON orders;

-- 2. Recréer la fonction avec la logique corrigée
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

-- 3. Recréer le trigger
CREATE TRIGGER check_product_availability_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION check_product_availability();

-- 4. Vérifier que le trigger a été recréé
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
AND trigger_name = 'check_product_availability_trigger';

-- 5. Tester avec le produit problématique (VERSION SIMPLIFIÉE)
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
    
    -- Afficher les informations
    RAISE NOTICE '=== TEST APRÈS CORRECTION ===';
    RAISE NOTICE 'ID: %', product_record.id;
    RAISE NOTICE 'Nom: %', product_record.name;
    RAISE NOTICE 'Quantité en stock: %', product_record.quantity;
    RAISE NOTICE 'Disponible: %', product_record.is_available;
    RAISE NOTICE 'Quantité demandée: %', requested_quantity;
    
    -- Tester la logique
    IF product_record.id IS NULL THEN
        RAISE NOTICE 'ERREUR: Le produit n''existe pas';
    ELSIF NOT product_record.is_available THEN
        RAISE NOTICE 'ERREUR: Le produit n''est pas disponible';
    ELSIF product_record.quantity < requested_quantity THEN
        RAISE NOTICE 'ERREUR: Quantité insuffisante';
    ELSE
        RAISE NOTICE 'SUCCES: Le produit est disponible!';
    END IF;
END $$;

-- Message de confirmation
SELECT 'Trigger check_product_availability corrigé avec succès!' as message;
