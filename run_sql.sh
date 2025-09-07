#!/bin/bash

# Script pour exécuter des requêtes SQL sur Supabase
# Usage: ./run_sql.sh nom_du_script.sql

# Charger la configuration
source ./supabase_connection.sh

# Vérifier qu'un fichier SQL est fourni
if [ $# -eq 0 ]; then
    echo "❌ Erreur: Veuillez spécifier un fichier SQL"
    echo "Usage: ./run_sql.sh nom_du_script.sql"
    echo ""
    echo "📋 Scripts disponibles:"
    ls -la *.sql | grep -v "run_sql.sh"
    exit 1
fi

SCRIPT_FILE=$1

# Vérifier que le fichier existe
if [ ! -f "$SCRIPT_FILE" ]; then
    echo "❌ Erreur: Le fichier $SCRIPT_FILE n'existe pas"
    exit 1
fi

echo "🚀 Exécution du script: $SCRIPT_FILE"
echo "📊 Connexion à: $DB_HOST:$DB_PORT/$DB_NAME"
echo ""

# Exécuter le script SQL
psql "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME" -f "$SCRIPT_FILE"

echo ""
echo "✅ Script exécuté avec succès !"
