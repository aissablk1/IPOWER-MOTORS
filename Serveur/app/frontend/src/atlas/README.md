# AtlasJS - IPOWER MOTORS

## 📖 Vue d'ensemble

AtlasJS est un framework JavaScript moderne utilisé par Microsoft's Developer Relations pour créer des applications web performantes et maintenables.

## 🚀 Installation

AtlasJS est déjà installé dans le projet :

```bash
pnpm add @microsoft/atlas-js
```

## 📁 Structure

```
src/atlas/
├── index.ts           # Configuration principale AtlasJS
├── components.ts      # Composants personnalisés IPOWER MOTORS
└── README.md         # Cette documentation
```

## ⚙️ Configuration

### Configuration de base

```typescript
// src/atlas/index.ts
import { Atlas } from '@microsoft/atlas-js';

export const atlasConfig = {
  theme: {
    colors: {
      primary: '#ff6b35', // Orange IPOWER MOTORS
      secondary: '#1a1a1a', // Noir IPOWER MOTORS
      accent: '#f97316',
    },
    fonts: {
      primary: 'Inter, system-ui, sans-serif',
      display: 'Poppins, Inter, system-ui, sans-serif',
    },
  },
  components: {
    // Composants personnalisés
  },
};

export const atlas = new Atlas(atlasConfig);
```

## 🧩 Composants personnalisés

### IPowerButton

Bouton personnalisé avec les couleurs IPOWER MOTORS.

```typescript
import { IPowerButton } from '../atlas/components';

// Utilisation
const button = new IPowerButton({
  variant: 'primary', // 'primary' | 'secondary' | 'outline'
  children: 'Mon bouton',
  onClick: () => console.log('Cliqué !'),
});
```

### IPowerCard

Carte personnalisée avec ombre et animations.

```typescript
import { IPowerCard } from '../atlas/components';

// Utilisation
const card = new IPowerCard({
  className: 'my-custom-class',
  children: '<h3>Titre de la carte</h3><p>Contenu...</p>',
});
```

### IPowerNavigation

Navigation personnalisée avec les couleurs IPOWER MOTORS.

```typescript
import { IPowerNavigation } from '../atlas/components';

// Utilisation
const navigation = new IPowerNavigation({
  items: [
    { href: '/', label: 'Accueil' },
    { href: '/services', label: 'Services' },
    { href: '/contact', label: 'Contact' },
  ],
});
```

## 🔄 Intégration avec React

### Exemple d'utilisation

```typescript
import React, { useEffect, useRef } from 'react';
import { atlas } from '../atlas';

const AtlasExample: React.FC = () => {
  const atlasRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (atlasRef.current) {
      // Initialiser AtlasJS
      atlas.init(atlasRef.current);
      
      // Créer un composant
      const button = atlas.createComponent('IPowerButton', {
        variant: 'primary',
        children: 'Bouton AtlasJS',
        onClick: () => console.log('Cliqué !'),
      });

      atlasRef.current.appendChild(button);
    }

    return () => {
      if (atlasRef.current) {
        atlas.destroy();
      }
    };
  }, []);

  return <div ref={atlasRef} />;
};
```

## 🎨 Thème et couleurs

### Couleurs IPOWER MOTORS

```typescript
const ipowerColors = {
  orange: '#ff6b35',    // Orange principal
  dark: '#1a1a1a',      // Noir principal
  glass: 'rgba(255, 255, 255, 0.1)',
  glassDark: 'rgba(0, 0, 0, 0.2)',
};
```

### Typographie

```typescript
const fonts = {
  primary: 'Inter, system-ui, sans-serif',
  display: 'Poppins, Inter, system-ui, sans-serif',
};
```

## 🔧 API Reference

### Atlas

#### `atlas.init(container: HTMLElement)`
Initialise AtlasJS dans un conteneur DOM.

#### `atlas.createComponent(name: string, props: any)`
Crée un composant AtlasJS personnalisé.

#### `atlas.destroy()`
Nettoie les ressources AtlasJS.

### Composants

#### IPowerButton
- `variant`: 'primary' | 'secondary' | 'outline'
- `children`: Contenu du bouton
- `onClick`: Fonction de callback

#### IPowerCard
- `className`: Classes CSS supplémentaires
- `children`: Contenu de la carte

#### IPowerNavigation
- `items`: Array d'objets avec `href` et `label`

## 🚀 Bonnes pratiques

1. **Initialisation** : Toujours initialiser AtlasJS dans un `useEffect`
2. **Cleanup** : Nettoyer les ressources avec `atlas.destroy()`
3. **Composants** : Utiliser les composants personnalisés IPOWER MOTORS
4. **Thème** : Respecter les couleurs et la typographie définies
5. **Performance** : Éviter les re-renders inutiles

## 📚 Ressources

- [Documentation officielle AtlasJS](https://github.com/microsoft/atlas-design)
- [Microsoft Atlas Design System](https://atlas.microsoft.com)
- [Exemples d'utilisation](https://github.com/microsoft/atlas-design/tree/main/examples)

## 🤝 Support

Pour toute question sur AtlasJS dans le projet IPOWER MOTORS, consultez cette documentation ou contactez l'équipe de développement. 