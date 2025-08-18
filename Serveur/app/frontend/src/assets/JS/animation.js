// animation.js – Carousel & Form

/* ---------- CAROUSEL ---------- */
const track   = document.querySelector('.carousel__track');
const prevBtn = document.querySelector('.carousel .prev');
const nextBtn = document.querySelector('.carousel .next');
const slideW  = () =>
    track.firstElementChild.getBoundingClientRect().width +
    parseFloat(getComputedStyle(track).columnGap || 24);

nextBtn.addEventListener('click', () =>
    track.scrollBy({ left: slideW(),  behavior: 'smooth' })
);
prevBtn.addEventListener('click', () =>
    track.scrollBy({ left:-slideW(),  behavior: 'smooth' })
);

/* Auto défilement */
setInterval(() =>
    track.scrollBy({ left: slideW(), behavior: 'smooth' })
, 5000);

/* Centrage après le scroll (évite l’offset) */
track.addEventListener('scrollend', () => {
    const slide = slideW();
    track.scrollTo({ left: Math.round(track.scrollLeft/slide)*slide, behavior:'auto' });
});

/* ---------- CONTACT FORM VALIDATION ---------- */
const form = document.getElementById('contact-form');
const msg  = document.getElementById('form-msg');

form.addEventListener('submit', e => {
    e.preventDefault();
    const data = Object.fromEntries(new FormData(form));
    if(Object.values(data).some(v => !v.trim())){
        showFeedback('Merci de remplir tous les champs.');
        return;
    }
    /* → brancher emailJS ou endpoint ici */
    showFeedback('Message envoyé ! 🚀', true);
    form.reset();
});

function showFeedback(text, ok=false){
    msg.textContent = text;
    msg.style.color = ok ? 'green' : 'crimson';
    msg.hidden = false;
    setTimeout(() => (msg.hidden = true), 4000);
}