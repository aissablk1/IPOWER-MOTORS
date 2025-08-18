/**
 * Services Interactions - Gestion des interactions pour les cartes de services
 * Améliore l'expérience utilisateur avec des animations et des effets visuels
 */

class ServicesInteractions {
    constructor() {
        this.cards = document.querySelectorAll('.card');
        this.servicesSection = document.querySelector('.hero__services');
        this.init();
    }

    init() {
        this.setupCardInteractions();
        this.setupIntersectionObserver();
        this.setupKeyboardNavigation();
        this.setupTouchInteractions();
    }

    /**
     * Configuration des interactions des cartes
     */
    setupCardInteractions() {
        this.cards.forEach((card, index) => {
            // Ajout d'un délai progressif pour l'animation
            card.style.animationDelay = `${index * 0.1}s`;

            // Gestion du hover avec effet de parallaxe léger
            card.addEventListener('mouseenter', (e) => {
                this.handleCardHover(e, card);
            });

            card.addEventListener('mouseleave', (e) => {
                this.handleCardLeave(e, card);
            });

            // Gestion du clic pour plus d'informations
            card.addEventListener('click', (e) => {
                this.handleCardClick(e, card);
            });

            // Gestion du focus pour l'accessibilité
            card.addEventListener('focus', (e) => {
                this.handleCardFocus(e, card);
            });
        });
    }

    /**
     * Effet de hover avec parallaxe léger
     */
    handleCardHover(e, card) {
        const rect = card.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        
        const centerX = rect.width / 2;
        const centerY = rect.height / 2;
        
        const rotateX = (y - centerY) / 10;
        const rotateY = (centerX - x) / 10;

        card.style.transform = `
            translateY(-8px) 
            scale(1.02) 
            rotateX(${rotateX}deg) 
            rotateY(${rotateY}deg)
        `;

        // Animation de l'icône
        const icon = card.querySelector('.card__icon');
        if (icon) {
            icon.style.transform = 'scale(1.15) rotate(8deg)';
        }
    }

    /**
     * Retour à l'état normal
     */
    handleCardLeave(e, card) {
        card.style.transform = 'translateY(0) scale(1) rotateX(0deg) rotateY(0deg)';
        
        const icon = card.querySelector('.card__icon');
        if (icon) {
            icon.style.transform = 'scale(1) rotate(0deg)';
        }
    }

    /**
     * Gestion du clic sur une carte
     */
    handleCardClick(e, card) {
        // Effet de ripple
        this.createRippleEffect(e, card);
        
        // Animation de feedback
        card.style.transform = 'scale(0.98)';
        setTimeout(() => {
            card.style.transform = 'scale(1)';
        }, 150);

        // Ici vous pouvez ajouter la logique pour ouvrir une modal
        // ou naviguer vers une page de service spécifique
        console.log('Carte cliquée:', card.querySelector('h2').textContent);
    }

    /**
     * Effet de ripple au clic
     */
    createRippleEffect(e, card) {
        const ripple = document.createElement('span');
        const rect = card.getBoundingClientRect();
        const size = Math.max(rect.width, rect.height);
        const x = e.clientX - rect.left - size / 2;
        const y = e.clientY - rect.top - size / 2;

        ripple.style.cssText = `
            position: absolute;
            width: ${size}px;
            height: ${size}px;
            left: ${x}px;
            top: ${y}px;
            background: radial-gradient(circle, rgba(139, 214, 255, 0.3) 0%, transparent 70%);
            border-radius: 50%;
            transform: scale(0);
            animation: ripple 0.6s linear;
            pointer-events: none;
        `;

        card.appendChild(ripple);

        setTimeout(() => {
            ripple.remove();
        }, 600);
    }

    /**
     * Gestion du focus pour l'accessibilité
     */
    handleCardFocus(e, card) {
        card.style.outline = '2px solid rgba(139, 214, 255, 0.8)';
        card.style.outlineOffset = '4px';
    }

    /**
     * Configuration de l'Intersection Observer pour les animations
     */
    setupIntersectionObserver() {
        const options = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }
            });
        }, options);

        this.cards.forEach(card => {
            observer.observe(card);
        });
    }

    /**
     * Navigation au clavier pour l'accessibilité
     */
    setupKeyboardNavigation() {
        document.addEventListener('keydown', (e) => {
            const focusedCard = document.querySelector('.card:focus');
            if (!focusedCard) return;

            const cards = Array.from(this.cards);
            const currentIndex = cards.indexOf(focusedCard);

            let nextIndex;

            switch (e.key) {
                case 'ArrowRight':
                    nextIndex = (currentIndex + 1) % cards.length;
                    break;
                case 'ArrowLeft':
                    nextIndex = (currentIndex - 1 + cards.length) % cards.length;
                    break;
                case 'ArrowDown':
                    nextIndex = (currentIndex + 2) % cards.length;
                    break;
                case 'ArrowUp':
                    nextIndex = (currentIndex - 2 + cards.length) % cards.length;
                    break;
                case 'Enter':
                case ' ':
                    e.preventDefault();
                    this.handleCardClick(e, focusedCard);
                    return;
                default:
                    return;
            }

            cards[nextIndex].focus();
        });
    }

    /**
     * Interactions tactiles pour mobile
     */
    setupTouchInteractions() {
        let touchStartTime = 0;
        let touchStartY = 0;

        this.cards.forEach(card => {
            card.addEventListener('touchstart', (e) => {
                touchStartTime = Date.now();
                touchStartY = e.touches[0].clientY;
            });

            card.addEventListener('touchend', (e) => {
                const touchEndTime = Date.now();
                const touchEndY = e.changedTouches[0].clientY;
                const touchDuration = touchEndTime - touchStartTime;
                const touchDistance = Math.abs(touchEndY - touchStartY);

                // Détection d'un tap (pas de scroll)
                if (touchDuration < 300 && touchDistance < 10) {
                    this.handleCardClick(e, card);
                }
            });
        });
    }

    /**
     * Animation de ripple pour les effets de clic
     */
    addRippleStyles() {
        if (!document.getElementById('ripple-styles')) {
            const style = document.createElement('style');
            style.id = 'ripple-styles';
            style.textContent = `
                @keyframes ripple {
                    to {
                        transform: scale(2);
                        opacity: 0;
                    }
                }
            `;
            document.head.appendChild(style);
        }
    }
}

// Initialisation quand le DOM est chargé
document.addEventListener('DOMContentLoaded', () => {
    // Vérification de la compatibilité
    if ('IntersectionObserver' in window && 'requestAnimationFrame' in window) {
        const servicesInteractions = new ServicesInteractions();
        servicesInteractions.addRippleStyles();
    } else {
        // Fallback pour les navigateurs plus anciens
        console.log('Fonctionnalités avancées non supportées, utilisation du mode basique');
    }
});

// Export pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ServicesInteractions;
} 