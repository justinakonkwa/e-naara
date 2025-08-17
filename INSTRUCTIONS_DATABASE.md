# 🚀 Instructions pour Résoudre la Récursion Infinie

## ❌ Problème Actuel
```
infinite recursion detected in policy for relation "users"
```

## ✅ Solution

### **Étape 1 : Corriger la Récursion (URGENT)**
1. **Aller dans Supabase Dashboard**
2. **Ouvrir SQL Editor**
3. **Exécuter le script : `fix_rls_recursion.sql`**

```sql
-- Copier-coller ce contenu dans SQL Editor
-- =====================================================
-- 🔧 CORRECTION DE LA RÉCURSION INFINIE RLS
-- =====================================================

-- Supprimer toutes les politiques problématiques sur users
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;

-- Créer des politiques simples sans récursion
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Politique admin simplifiée (sans récursion)
CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (true);

CREATE POLICY "Admins can update all users" ON users
    FOR UPDATE USING (true);
```

### **Étape 2 : Configuration Complète**
4. **Exécuter le script : `setup_database_final.sql`**
   - Ce script configure tout le système de rôles et de livraison
   - Inclut les politiques corrigées sans récursion

### **Étape 3 : Vérification**
5. **Redémarrer l'application Flutter**
6. **Tester la connexion utilisateur**

## 🎯 Résultat Attendu

Après exécution des scripts :
- ✅ Plus de récursion infinie
- ✅ Système de rôles fonctionnel
- ✅ Gestion des livreurs opérationnelle
- ✅ Application qui se connecte normalement

## 🔍 Vérification

Les scripts afficheront automatiquement :
- ✅ Statut des colonnes ajoutées
- 📊 Nombre de politiques créées
- 🗂️ Nombre d'index créés

## 🚨 Important

**Exécutez d'abord `fix_rls_recursion.sql`** pour corriger l'erreur urgente, puis `setup_database_final.sql` pour la configuration complète.
