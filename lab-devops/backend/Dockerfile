# 1. Image de base
FROM node:20-alpine

# 2. Dossier de travail dans le conteneur
WORKDIR /app

# 3. Copie des fichiers de dépendances
COPY package*.json ./

# 4. Installation des dépendances
RUN npm install

# 5. Copie de l'ensemble du code source
COPY . .

# 6. Exposition du port
EXPOSE 3001

# 7. Commande d'exécution
CMD ["npm", "run", "start:dev"]
