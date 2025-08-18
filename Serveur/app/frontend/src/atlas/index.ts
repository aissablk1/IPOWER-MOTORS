// AtlasJS - Framework JavaScript pour applications web modernes
// Documentation: https://github.com/microsoft/atlas-design

import { 
  initDismiss, 
  initPopover, 
  initSnapScroll, 
  initLayout,
  generateElementId,
  kebabToCamelCase 
} from '@microsoft/atlas-js';

// Configuration AtlasJS pour IPOWER MOTORS
export const atlasConfig = {
  // Configuration personnalisée pour IPOWER MOTORS
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
  // Configuration des comportements
  behaviors: {
    dismiss: true,
    popover: true,
    snapScroll: true,
    layout: true,
  },
};

// Classe AtlasJS personnalisée pour IPOWER MOTORS
export class Atlas {
  private config: typeof atlasConfig;

  constructor(config: typeof atlasConfig) {
    this.config = config;
  }

  // Initialiser tous les comportements AtlasJS
  init() {
    if (this.config.behaviors.dismiss) {
      initDismiss();
    }
    if (this.config.behaviors.popover) {
      initPopover();
    }
    if (this.config.behaviors.snapScroll) {
      initSnapScroll();
    }
    if (this.config.behaviors.layout) {
      initLayout();
    }
  }

  // Générer un ID unique
  generateId(): string {
    return generateElementId();
  }

  // Convertir kebab-case en camelCase
  toCamelCase(str: string): string {
    return kebabToCamelCase(str);
  }
}

// Instance AtlasJS configurée
export const atlas = new Atlas(atlasConfig);

// Export des utilitaires AtlasJS
export { 
  initDismiss, 
  initPopover, 
  initSnapScroll, 
  initLayout,
  generateElementId,
  kebabToCamelCase 
};

// Composants AtlasJS personnalisés pour IPOWER MOTORS
export * from './components'; 