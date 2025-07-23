let currentTimer = 0;
let maxTimer = 0;

// Écoute des événements depuis FiveM
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'showDeath':
            showDeathInterface(data.cat, data.koTime);
            break;
        case 'updateTimer':
            updateTimer(data.timeLeft);
            break;
        case 'hideDeath':
            hideDeathInterface();
            break;
    }
});

function showDeathInterface(deathType, totalTime) {
    const container = document.getElementById('deathContainer');
    const icon = document.getElementById('deathIcon');
    const title = document.getElementById('deathTitle');
    const message = document.getElementById('deathMessage');
    
    maxTimer = totalTime;
    currentTimer = totalTime;
    
    // Personnalise selon le type de mort
    switch(deathType) {
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
        default:
            icon.textContent = '💀';
            title.textContent = 'Inconscient';
            message.textContent = 'Vous êtes dans le coma...';
    }
    
    // Affiche l'interface
    container.classList.remove('hidden');
    updateProgressRing(currentTimer, maxTimer);
}

function updateTimer(timeLeft) {
    currentTimer = timeLeft;
    document.getElementById('timeLeft').textContent = timeLeft;
    updateProgressRing(timeLeft, maxTimer);
}

function updateProgressRing(current, max) {
    const circle = document.querySelector('.progress-ring-circle');
    const circumference = 2 * Math.PI * 54; // rayon = 54
    const progress = current / max;
    const offset = circumference * (1 - progress);
    
    circle.style.strokeDashoffset = offset;
}

function hideDeathInterface() {
    document.getElementById('deathContainer').classList.add('hidden');
}
