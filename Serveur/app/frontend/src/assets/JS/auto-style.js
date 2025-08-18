// auto-style.js

/**
 * 🎯 Applique dynamiquement les variables CSS --radius et --shadow en fonction
 * de la largeur du composant (responsive border-radius et ombre).
 * 
 * Cela permet de créer un design fluide où les coins et les ombres s’adaptent
 * automatiquement à la taille du composant.
 */

// Définition des seuils de largeur pour le rayon de bordure (--radius)
const radiusThresholds = [
    { max: 64, value: 'var(--radius-sm)' },       // Si largeur ≤ 64px → petit radius
    { max: 128, value: 'var(--radius-md)' },      // Si largeur ≤ 128px → medium radius
    { max: 192, value: 'var(--radius-lg)' },      // Si largeur ≤ 192px → grand radius
    { max: 256, value: 'var(--radius-xl)' },      // Si largeur ≤ 256px → très grand radius
    { max: Infinity, value: 'var(--radius-2xl)' } // Si largeur > 256px → radius XL+
];

// Définition des seuils de largeur pour l'ombre portée (--shadow)
const shadowThresholds = [
    { max: 64,  value: 'var(--shadow-xs)' },     // boutons, icônes
    { max: 128,  value: 'var(--shadow-sm)' },     // petites cards
    { max: 192,  value: 'var(--shadow-md)' },     // modales, popups
    { max: 256,  value: 'var(--shadow-lg)' },     // panneaux latéraux
    { max: Infinity, value: 'var(--shadow-xl)' }  // overlays, grosses zones
];

// Fonction qui observe un élément et ajuste dynamiquement son --radius et --shadow
function autoAdjustStyle(element) {
    // Instancie un nouvel observateur de redimensionnement
    const observer = new ResizeObserver(entries => {
        for (const entry of entries) {
            // Récupère la largeur actuelle de l'élément observé
            const width = entry.contentRect.width; // Récupère la largeur visible du composant

            // Recherche la bonne valeur de radius en fonction de la largeur
            const radiusMatch = radiusThresholds.find(t => width <= t.max);
            // Recherche la bonne valeur de shadow en fonction de la largeur
            const shadowMatch = shadowThresholds.find(t => width <= t.max);
            // Si les deux correspondances sont trouvées, on applique les styles
            if (radiusMatch && shadowMatch) {
                entry.target.style.setProperty('--radius', radiusMatch.value);
                entry.target.style.setProperty('--shadow', shadowMatch.value);
            }
        }
    });

    // Lance l'observation de cet élément
    observer.observe(element);
}

/**
 * 🔁 Fonction d’initialisation : sélectionne tous les éléments
 * ayant l’attribut [data-auto-radius] et active l’observateur
 */
function initAutoStyle() {
    // Sélectionne tous les éléments HTML avec l'attribut data-auto-radius
    const elements = document.querySelectorAll('[data-auto-radius]'); // Recherche des éléments ciblés
    // Applique l'observateur à chaque élément sélectionné
    elements.forEach(autoAdjustStyle);                               // Applique l’observateur à chacun
}

// Lance l'initialisation dès que le DOM est complètement chargé
window.addEventListener('DOMContentLoaded', initAutoStyle);