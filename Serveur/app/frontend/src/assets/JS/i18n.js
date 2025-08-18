import i18next from 'https://cdn.skypack.dev/i18next@23';
export let lang;
export async function changeLang(l){
    localStorage.setItem('lang',l);location.reload();
}

(
    async()=>{
        const list = ['fr','en','es','de','it','pt','zh','ar'];
        const fallback='fr';
        const saved = localStorage.getItem('lang');
        const browser=navigator.language.slice(0,2);
        lang = saved ?? (list.includes(browser)?browser:fallback);

        await i18next.init({lng:lang,fallbackLng:fallback,resources:{}});
        const res = await fetch(`/assets/locales/${lang}/translation.json`).then(r=>r.json());
        i18next.addResourceBundle(lang,'translation',res);
        document.querySelectorAll('[data-i18n]').forEach(el=>{
            el.innerHTML=i18next.t(el.dataset.i18n);
        });
        document.documentElement.lang = lang;
    }
)();