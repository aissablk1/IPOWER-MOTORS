// scroll.js – Parallax léger & interactions
/* ----------  BURGER NAV  ---------- */
const burger  = document.querySelector('.burger');
const nav     = document.querySelector('.nav');

burger.addEventListener('click', () => {
  const expanded = burger.getAttribute('aria-expanded') === 'true' || false;
  burger.setAttribute('aria-expanded', !expanded);
  nav.classList.toggle('open');
});

/* ----------  LANG SWITCHER  ---------- */
import { changeLang, lang } from '/assets/JS/i18n.js';
const switcher = document.getElementById('lang-switcher');
switcher.value = lang;
switcher.addEventListener('change', e => changeLang(e.target.value));