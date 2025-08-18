#!/usr/bin/env node

// ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
// ┃              proxy.js - Proxy HTTP local          ┃
// ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

const http = require('http');
const { execSync } = require('child_process');
const os = require('os');
const fs = require('fs');
const path = require('path');
// 🔁 Vérifie et installe le module http-proxy si nécessaire
try {
    require.resolve('http-proxy');
} catch (e) {
    console.log('📦 Installation du module "http-proxy"…');
    execSync('npm install http-proxy', { stdio: 'inherit' });
}
const httpProxy = require('http-proxy');
// 🔁 Vérifie et installe le module readline-sync si nécessaire
let readlineSync;
try {
    readlineSync = require('readline-sync');
} catch (err) {
    console.error("📦 Module 'readline-sync' manquant. Tentative d’installation…");
    const { execSync } = require('child_process');
    try {
        execSync('npm install readline-sync --save', { stdio: 'inherit' });
        readlineSync = require('readline-sync');
    } catch (installError) {
        console.error("❌ Impossible d’installer 'readline-sync'. Veuillez l’installer manuellement.");
        process.exit(1);
    }
}

// 🌐 Configuration du domaine personnalisé
const customDomain = process.env.CUSTOM_DOMAIN ?? 'ipowerfrance';
const customExtension = process.env.CUSTOM_EXTENSION ?? '.local';
const fullDomain = `${customDomain}${customExtension}`;

// 🔌 Récupération du port cible
const targetPort = process.env.JEKYLL_PORT;

if (!targetPort) {
    console.error('❌ Variable d\'environnement JEKYLL_PORT manquante.');
    process.exit(1);
}

// 🔁 Mode export CLI : retourne les variables si appelé directement
if (require.main === module && process.argv.includes('--export')) {
    console.log(`CUSTOM_DOMAIN=${customDomain}`);
    console.log(`CUSTOM_EXTENSION=${customExtension}`);
    console.log(`FULL_DOMAIN=${fullDomain}`);
    process.exit(0);
}

// 🛠️ Ajoute ipowerfrance.local à /etc/hosts si manquant
function ensureCustomHostExists(fullDomain) {
    const hostsPath = '/etc/hosts';
    const lineToAdd = `127.0.0.1\t${fullDomain}`;

    try {
        const content = fs.readFileSync(hostsPath, 'utf8');
        if (!content.includes(fullDomain)) {
            console.log(`➕ Domaine ${fullDomain} non trouvé. Ajout via sudo...`);
            console.log(`\n🔐 Une élévation de privilèges est requise pour modifier ${hostsPath}.`);
            console.log(`⏸️  Appuie sur Entrée pour continuer et taper ton mot de passe sudo...`);
            readlineSync.question(); // Pause jusqu'à appui sur Entrée
            try {
                execSync(`echo '${lineToAdd}' | sudo tee -a "${hostsPath}" > /dev/null`, { stdio: 'inherit' });
                console.log(`✅ ${fullDomain} ajouté à ${hostsPath}`);
            } catch (sudoErr) {
                console.error(`❌ Échec de l'ajout du domaine avec sudo :`, sudoErr.message);
                console.log(`ℹ️  Essayez d'exécuter manuellement :\necho '${lineToAdd}' | sudo tee -a "${hostsPath}"`);
                process.exit(1);
            }
        } else {
            console.log(`✔️ Domaine ${fullDomain} déjà présent dans ${hostsPath}`);
        }
    } catch (err) {
        console.error(`❌ Échec lors de la lecture de ${hostsPath}`, err.message);
        console.log(`ℹ️  Ajoutez manuellement :\n${lineToAdd}`);
    }
}

// ⚙️ Détection OS + appel
const platform = os.platform();
const arch = os.arch();
console.log('⧓ Plateforme détectée :', platform, arch);

if (['darwin', 'linux'].includes(platform)) {
    ensureCustomHostExists(fullDomain);
} else {
    console.warn(`❌ OS non pris en charge automatiquement : ${platform}`);
}

// 🧭 Création du proxy
const proxy = httpProxy.createProxyServer({});

// 🧯 Gestion des erreurs proxy
proxy.on('error', (err, req, res) => {
    console.error('⚠️ Erreur proxy :', err.message);
    if (!res.headersSent) {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
    }
    res.end('Erreur serveur proxy : ' + err.message);
});

// 🚀 Démarrage du serveur HTTP de redirection
http.createServer((req, res) => {
    proxy.web(req, res, { target: `http://localhost:${targetPort}` }, (err) => {
        console.error('❌ Échec de redirection proxy :', err.message);
        res.writeHead(502, { 'Content-Type': 'text/plain' });
        res.end('Erreur proxy : ' + err.message);
    });
}).listen(80, () => {
    console.log(`🚀 Proxy opérationnel sur http://${fullDomain} → http://localhost:${targetPort}`);
});