// countdown.js — Compte à rebours IPOWER MOTORS

const countdown = document.getElementById('countdown');

// Date de lancement du site
const launchDate = new Date("2025-06-01T00:00:00").getTime();

function updateCountdown() {
    const now = new Date().getTime();
    const distance = launchDate - now;

    if (distance <= 0) {
        countdown.innerHTML = "🚀 Le site est maintenant en ligne, BIENVENUE !";
        return;
    }

    const days    = Math.floor(distance / (1000 * 60 * 60 * 24));
    const hours   = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((distance % (1000 * 60)) / 1000);

    countdown.innerHTML = `
        <div class="countdown-unit">
            <div class="countdown-value">${String(days).padStart(2,'0')}</div>
            <div class="countdown-label">Jours</div>
        </div>
        <div class="countdown-separator">:</div>
        <div class="countdown-unit">
            <div class="countdown-value">${String(hours).padStart(2,'0')}</div>
            <div class="countdown-label">Heures</div>
        </div>
        <div class="countdown-separator">:</div>
        <div class="countdown-unit">
            <div class="countdown-value">${String(minutes).padStart(2,'0')}</div>
            <div class="countdown-label">Minutes</div>
        </div>
        <div class="countdown-separator">:</div>
        <div class="countdown-unit">
            <div class="countdown-value">${String(seconds).padStart(2,'0')}</div>
            <div class="countdown-label">Secondes</div>
        </div>
    `;
}

setInterval(updateCountdown, 1000);
updateCountdown();