let currentTimer = 0;
let maxTimer = 0;

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'init' && data.module === 'coma') {
        if (data.data && data.data.cat && data.data.koTime) {
            showDeathInterface(data.data.cat, data.data.koTime);
        }
        return;
    }

    if (data.action === 'update' && data.module === 'coma') {
        if (data.data && data.data.timeLeft !== undefined) {
            updateTimer(data.data.timeLeft);
        }
        return;
    }
});

function showDeathInterface(deathType, totalTime) {

    const container = document.getElementById('deathContainer');
    const icon = document.getElementById('deathIcon');
    const title = document.getElementById('deathTitle');
    const message = document.getElementById('deathMessage');

    if (!container || !icon || !title || !message) {
        console.error('[Coma Script] Elements DOM non trouvés:', {
            container: !!container,
            icon: !!icon,
            title: !!title,
            message: !!message
        });

        setTimeout(() => {
            showDeathInterface(deathType, totalTime);
        }, 100);
        return;
    }

    maxTimer = totalTime;
    currentTimer = totalTime;

    switch (deathType) {
        case 'unarmed':
            icon.textContent = '💫';
            title.textContent = 'Vous êtes KO';
            message.textContent = 'Vous avez pris trop de coups...';
            break;
        case 'knife':
            icon.textContent = '🔪';
            title.textContent = 'Blessure grave';
            message.textContent = 'Vous saignez abondamment...';
            break;
        case 'gun':
            icon.textContent = '🔴';
            title.textContent = 'État critique';
            message.textContent = 'Vous avez reçu une balle...';
            break;
        case 'hunger':
            icon.textContent = '🍽️';
            title.textContent = 'Faim extrême';
            message.textContent = 'Vous êtes en train de mourir de faim...';
            break;
        case 'thirst':
            icon.textContent = '💧';
            title.textContent = 'Déshydratation';
            message.textContent = 'Vous êtes en train de mourir de soif...';
            break;
        default:
            icon.textContent = '💀';
            title.textContent = 'Inconscient';
            message.textContent = 'Vous êtes dans le coma...';
    }

    container.classList.remove('hidden');
    updateProgressRing(currentTimer, maxTimer);
}

function updateTimer(timeLeft) {
    currentTimer = timeLeft;
    const timeLeftElement = document.getElementById('timeLeft');
    if (timeLeftElement) {
        timeLeftElement.textContent = timeLeft;
    }
    updateProgressRing(timeLeft, maxTimer);
}

function updateProgressRing(current, max) {
    const circle = document.querySelector('.progress-ring-circle');
    if (!circle) {
        console.error('[Coma Script] Progress ring circle not found');
        return;
    }

    const circumference = 2 * Math.PI * 54; // rayon = 54
    const progress = current / max;
    const offset = circumference * (1 - progress);

    circle.style.strokeDashoffset = offset;
}

function hideDeathInterface() {
    const container = document.getElementById('deathContainer');
    if (container) {
        container.classList.add('hidden');
    }
}

setTimeout(() => {
    const elements = {
        deathContainer: !!document.getElementById('deathContainer'),
        deathIcon: !!document.getElementById('deathIcon'),
        deathTitle: !!document.getElementById('deathTitle'),
        deathMessage: !!document.getElementById('deathMessage'),
        timeLeft: !!document.getElementById('timeLeft'),
        progressRing: !!document.querySelector('.progress-ring-circle')
    };

    if (!elements.deathContainer) {
        console.error('[Coma Script] ERREUR: Container principal non trouvé!');
    }
}, 500);