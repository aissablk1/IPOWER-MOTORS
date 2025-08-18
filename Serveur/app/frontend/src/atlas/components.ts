// Composants AtlasJS personnalisés pour IPOWER MOTORS

// Interface pour les props des composants
interface ComponentProps {
  [key: string]: any;
}

// Composant Button personnalisé avec les couleurs IPOWER MOTORS
export class IPowerButton {
  private props: ComponentProps;

  constructor(props: ComponentProps) {
    this.props = props;
  }

  render(): HTMLElement {
    const { children, variant = 'primary', onClick, ...otherProps } = this.props;
    
    const baseClasses = 'px-6 py-3 rounded-lg font-medium transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2';
    
    const variants = {
      primary: 'bg-ipower-orange hover:bg-orange-600 text-white focus:ring-ipower-orange',
      secondary: 'bg-ipower-dark hover:bg-gray-800 text-white focus:ring-ipower-dark',
      outline: 'border-2 border-ipower-orange text-ipower-orange hover:bg-ipower-orange hover:text-white',
    };

    const button = document.createElement('button');
    button.className = `${baseClasses} ${variants[variant as keyof typeof variants] || variants.primary}`;
    button.textContent = children || '';
    
    if (onClick) {
      button.addEventListener('click', onClick);
    }

    // Ajouter les autres props
    Object.entries(otherProps).forEach(([key, value]) => {
      if (key.startsWith('data-')) {
        button.setAttribute(key, value);
      } else if (key !== 'children' && key !== 'variant' && key !== 'onClick') {
        (button as any)[key] = value;
      }
    });

    return button;
  }
}

// Composant Card personnalisé
export class IPowerCard {
  private props: ComponentProps;

  constructor(props: ComponentProps) {
    this.props = props;
  }

  render(): HTMLElement {
    const { children, className = '', ...otherProps } = this.props;
    
    const card = document.createElement('div');
    card.className = `bg-white rounded-xl shadow-lg border border-gray-200 p-6 hover:shadow-xl transition-shadow duration-300 ${className}`;
    
    if (typeof children === 'string') {
      card.innerHTML = children;
    } else if (children instanceof HTMLElement) {
      card.appendChild(children);
    }

    // Ajouter les autres props
    Object.entries(otherProps).forEach(([key, value]) => {
      if (key.startsWith('data-')) {
        card.setAttribute(key, value);
      } else if (key !== 'children' && key !== 'className') {
        (card as any)[key] = value;
      }
    });

    return card;
  }
}

// Composant Navigation personnalisé
export class IPowerNavigation {
  private props: ComponentProps;

  constructor(props: ComponentProps) {
    this.props = props;
  }

  render(): HTMLElement {
    const { items = [], ...otherProps } = this.props;
    
    const nav = document.createElement('nav');
    nav.className = 'flex items-center space-x-8';
    
    items.forEach((item: any) => {
      const link = document.createElement('a');
      link.href = item.href || '#';
      link.textContent = item.label || '';
      link.className = 'text-gray-700 hover:text-ipower-orange transition-colors duration-200 font-medium';
      nav.appendChild(link);
    });

    // Ajouter les autres props
    Object.entries(otherProps).forEach(([key, value]) => {
      if (key.startsWith('data-')) {
        nav.setAttribute(key, value);
      } else if (key !== 'items') {
        (nav as any)[key] = value;
      }
    });

    return nav;
  }
}

// Fonction utilitaire pour créer des composants
export function createComponent(name: string, props: ComponentProps): HTMLElement {
  switch (name) {
    case 'IPowerButton':
      return new IPowerButton(props).render();
    case 'IPowerCard':
      return new IPowerCard(props).render();
    case 'IPowerNavigation':
      return new IPowerNavigation(props).render();
    default:
      throw new Error(`Composant ${name} non trouvé`);
  }
}

// Export des composants
export const components = {
  IPowerButton,
  IPowerCard,
  IPowerNavigation,
  createComponent,
}; 