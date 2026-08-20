#!/usr/bin/env bash
# backup_db.sh — Script de sauvegarde de base de données PostgreSQL

set -euo pipefail

# Définition des couleurs ANSI
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Reset color

# 1. Demander le nom de la base de données
read -p "Entrez le nom de la base de données à sauvegarder : " DB_NAME

if [ -z "$DB_NAME" ]; then
  echo -e "${RED}Erreur : Aucun nom de base de données saisi.${NC}"
  exit 1
fi

# 2. Créer le dossier 'backups' s'il n'existe pas
BACKUP_DIR="backups"
mkdir -p "$BACKUP_DIR"

# 3. Générer le fichier horodaté (ex: backups/sauvegarde_2026-08-20.sql)
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="${BACKUP_DIR}/sauvegarde_${DATE}.sql"

echo "Lancement de la sauvegarde pour '${DB_NAME}'..."

# Utilisation de pg_dump
pg_dump "$DB_NAME" > "$BACKUP_FILE"

# 4. Afficher le message de succès en vert
echo -e "${GREEN}✅ Sauvegarde terminée avec succès ! Fichier généré : ${BACKUP_FILE}${NC}"
