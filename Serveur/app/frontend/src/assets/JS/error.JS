const queue = [];
let showing = false;

function enqueueNotification(message) {
    queue.push(message);
    if (!showing) showNext();
}

function showNext() {
    if (queue.length === 0) return;
    showing = true;

    const message = queue.shift();
    const container = getNotificationContainer();

    const notif = document.createElement('div');
    notif.classList.add('notification');
    notif.innerText = message;
    notif.style.background = '#1e1e1e';
    notif.style.color = '#fff';
    notif.style.borderRadius = '6px';
    notif.style.padding = '12px 20px';
    notif.style.boxShadow = '0 2px 8px rgba(0, 0, 0, 0.3)';
    notif.style.fontFamily = 'monospace';
    notif.style.fontSize = '14px';
    notif.style.marginBottom = '10px';
    container.appendChild(notif);

    setTimeout(() => {
        notif.remove();
        showing = false;
        showNext();
    }, 5000);
}

function getNotificationContainer() {
    let container = document.getElementById('notification-container');
    if (!container) {
        container = document.createElement('div');
        container.id = 'notification-container';
        container.style.position = 'fixed';
        container.style.bottom = '20px';
        container.style.right = '20px';
        container.style.display = 'flex';
        container.style.flexDirection = 'column';
        container.style.gap = '10px';
        container.style.zIndex = '9999';
        document.body.appendChild(container);
    }
    return container;
}

window.addEventListener('error', function(event) {
    enqueueNotification(`🛑 Erreur : ${event.message} (ligne ${event.lineno})`);
});

window.addEventListener('unhandledrejection', function(event) {
    enqueueNotification(`⚠️ Rejection : ${event.reason}`);
});