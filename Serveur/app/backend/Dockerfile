# Dockerfile pour le backend IPOWER MOTORS - Optimisé pour AWS EC2
FROM node:18-alpine AS builder

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./
COPY pnpm-lock.yaml* ./

# Installer les dépendances
RUN npm install -g pnpm
RUN pnpm install --frozen-lockfile

# Copier le code source
COPY . .

# Build de l'application
RUN pnpm run build

# Image de production
FROM node:18-alpine AS production

# Créer un utilisateur non-root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./
COPY pnpm-lock.yaml* ./

# Installer uniquement les dépendances de production
RUN npm install -g pnpm
RUN pnpm install --frozen-lockfile --prod

# Copier les fichiers buildés depuis l'étape de build
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# Copier les fichiers de configuration
COPY --chown=nodejs:nodejs .env* ./

# Changer vers l'utilisateur non-root
USER nodejs

# Exposer le port
EXPOSE 3001

# Variables d'environnement par défaut
ENV NODE_ENV=production
ENV PORT=3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Commande de démarrage
CMD ["node", "dist/server.js"]
