#!/usr/bin/env bash
# init_dev.sh — Initialise la structure du projet lab-devops
# Usage : ./init_dev.sh

set -euo pipefail

PROJECT_NAME="lab-devops"
PROJECT_DIR="${PROJECT_NAME}"

echo "🚀 Initialisation du projet DevOps..."

# Création du dossier racine
mkdir -p "${PROJECT_DIR}"

# Structure backend (NestJS) et frontend (React)
mkdir -p "${PROJECT_DIR}/backend"
mkdir -p "${PROJECT_DIR}/frontend"

# Fichiers .env vides dans chaque dossier
touch "${PROJECT_DIR}/backend/.env"
touch "${PROJECT_DIR}/frontend/.env"

# README à la racine du projet
cat > "${PROJECT_DIR}/README.md" << 'EOF'
Environnement automatisé pour Ghislain
EOF

echo "✅ Projet '${PROJECT_NAME}' créé avec succès !"
echo ""
echo "Structure générée :"
find "${PROJECT_DIR}" -print | sed 's|[^/]*/|  |g'
