import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

// https://vite.dev/config/
export default defineConfig(({ command, mode }) => {
  // Charger les variables d'environnement
  const env = loadEnv(mode, process.cwd(), '')
  
  return {
    // Configuration de build optimisée pour AWS S3 + CloudFront
    build: {
      outDir: 'dist',
      sourcemap: mode === 'development',
      minify: mode === 'production',
      rollupOptions: {
        output: {
          // Chunking optimisé pour le cache CloudFront
          manualChunks: {
            vendor: ['react', 'react-dom'],
            router: ['react-router-dom'],
            ui: ['@headlessui/react', '@heroicons/react'],
            utils: ['lodash', 'date-fns', 'zod']
          },
          // Noms de fichiers avec hash pour le cache
          chunkFileNames: 'assets/js/[name]-[hash].js',
          entryFileNames: 'assets/js/[name]-[hash].js',
          assetFileNames: (assetInfo) => {
            const info = assetInfo.name?.split('.') || []
            const ext = info[info.length - 1]
            if (/\.(css)$/.test(assetInfo.name || '')) {
              return `assets/css/[name]-[hash].${ext}`
            }
            if (/\.(png|jpe?g|svg|gif|tiff|bmp|ico)$/i.test(assetInfo.name || '')) {
              return `assets/images/[name]-[hash].${ext}`
            }
            if (/\.(woff2?|eot|ttf|otf)$/i.test(assetInfo.name || '')) {
              return `assets/fonts/[name]-[hash].${ext}`
            }
            return `assets/[name]-[hash].${ext}`
          }
        }
      },
      // Optimisations pour la production
      target: 'es2015',
      cssCodeSplit: true,
      reportCompressedSize: false
    },
    
    // Configuration des alias pour les imports
    resolve: {
      alias: {
        '@': resolve(__dirname, 'src'),
        '@components': resolve(__dirname, 'src/components'),
        '@assets': resolve(__dirname, 'src/assets'),
        '@utils': resolve(__dirname, 'src/utils'),
        '@hooks': resolve(__dirname, 'src/hooks'),
        '@types': resolve(__dirname, 'src/types')
      }
    },
    
    // Configuration du serveur de développement
    server: {
      port: parseInt(env.VITE_DEV_PORT || '5173'),
      host: true,
      open: false
    },
    
    // Configuration des variables d'environnement
    define: {
      __APP_VERSION__: JSON.stringify(env.VITE_APP_VERSION || '1.0.0'),
      __APP_ENVIRONMENT__: JSON.stringify(env.VITE_APP_ENVIRONMENT || 'development')
    },
    
    // Configuration des plugins
    plugins: [
      react(),
      // Plugin personnalisé pour AWS
      {
        name: 'aws-optimization',
        generateBundle(options, bundle) {
          if (mode === 'production') {
            // Ajouter des en-têtes pour S3/CloudFront
            Object.keys(bundle).forEach(fileName => {
              const file = bundle[fileName]
              if (file.type === 'asset' && file.source) {
                // Optimisations pour les images
                if (/\.(png|jpe?g|svg|gif|webp)$/i.test(fileName)) {
                  // Ajouter des métadonnées pour l'optimisation
                  // Note: Les métadonnées AWS seront gérées par le script de déploiement
                  console.log(`Asset optimisé pour AWS: ${fileName}`)
                }
              }
            })
          }
        }
      }
    ]
  }
})
