#!/bin/bash

# Configuration Supabase pour les commandes SQL
# Projet: ckocfgadkxbkiocyiirb

# Variables de connexion
export SUPABASE_URL="https://ckocfgadkxbkiocyiirb.supabase.co"
export SUPABASE_PROJECT_ID="ckocfgadkxbkiocyiirb"
export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrb2NmZ2Fka3hia2lvY3lpaXJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwOTgyNzgsImV4cCI6MjA3MDY3NDI3OH0._CTAnJe0Obz5BXUx1C24BNtsHuHIMtrRX5sj84f-1DM"

# Informations de connexion PostgreSQL (à récupérer depuis le dashboard Supabase)
# Ces informations se trouvent dans: Dashboard > Settings > Database
export DB_HOST="db.ckocfgadkxbkiocyiirb.supabase.co"
export DB_PORT="5432"
export DB_NAME="postgres"
export DB_USER="postgres"
export DB_PASSWORD="postgres"  # À remplacer par votre vrai mot de passe

echo "🔧 Configuration Supabase chargée !"
echo "📊 URL: $SUPABASE_URL"
echo "🗄️  Base de données: $DB_HOST:$DB_PORT/$DB_NAME"
echo ""
echo "📋 Commandes utiles:"
echo "  • psql \"postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME\" -f script.sql"
echo "  • supabase status"
echo "  • supabase db reset"
echo ""
echo "⚠️  IMPORTANT: Remplacez le mot de passe par votre vrai mot de passe !"
echo "   Vous le trouvez dans: Dashboard Supabase > Settings > Database"
