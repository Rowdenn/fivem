let notificationCount = 0;
let notifications = [];
const maxNotifications = 10;
let proximityNotification = null;

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.module === 'notify' && data.data && data.data.message) {
        if (data.action === 'init' || data.action === 'show') {
            if (data.data.proximity !== true) {
                showNotification(data.data);
            }
            return;
        }
    }

    if (data.action === 'showProximityNotification') {
        showProximityNotification(data.data);
        return;
    }

    if (data.action === 'hideProximityNotification') {
        hideProximityNotification();
        return;
    }
});

function showNotification(data) {
    if (notifications.length >= maxNotifications) {
        removeOldestNotification();
    }

    const notification = createNotificationElement(data);
    const container = document.getElementById('notification-container'); // CONTAINER DU BAS

    if (!container) {
        console.error('Container notification-container not found!');
        return;
    }

    container.appendChild(notification);
    notifications.push(notification);

    setTimeout(() => {
        notification.classList.add('show');
    }, 100);

    const progressBar = notification.querySelector('.notification-progress');
    if (progressBar) {
        progressBar.style.width = '100%';
        setTimeout(() => {
            progressBar.style.width = '0%';
            progressBar.style.transitionDuration = `${data.duration}ms`;
        }, 100);
    }

    setTimeout(() => {
        removeNotification(notification);
    }, data.duration || 5000);
}

function createNotificationElement(data) {
    const notification = document.createElement('div');
    notification.className = `notification ${data.type || 'info'}`;
    notification.id = `notification-${++notificationCount}`;

    let imageHtml = '';
    if (data.image) {
        imageHtml = `<img src="${data.image}" alt="Notification" class="notification-image" onerror="this.style.display='none';">`;
    }

    notification.innerHTML = `
        ${imageHtml}
        <div class="notification-content">
            <p class="notification-message">${data.message}</p>
        </div>
        <div class="notification-progress"></div>
    `;

    return notification;
}

function removeNotification(notification) {
    if (!notification || !notification.parentNode) return;

    const index = notifications.indexOf(notification);
    if (index > -1) {
        notifications.splice(index, 1);
    }

    notification.classList.add('hide');

    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 400);
}

function removeOldestNotification() {
    if (notifications.length > 0) {
        removeNotification(notifications[0]);
    }
}

function clearAllNotifications() {
    notifications.forEach(notification => {
        removeNotification(notification);
    });
    notifications = [];
}

function showProximityNotification(data) {
    const notification = document.createElement('div');
    notification.className = 'notification proximity';
    notification.id = `proximity-notification-${++notificationCount}`;

    notification.innerHTML = `
        <div class="notification-content">
            <p class="notification-message">${data.message}</p>
        </div>
    `;

    const container = document.getElementById('proximity-notification-container');

    if (!container) {
        console.error('Container proximity-notification-container not found!');
        return;
    }

    container.appendChild(notification);

    setTimeout(() => {
        notification.classList.add('show');
    }, 100);

    proximityNotification = notification;
}

function hideProximityNotification() {
    if (proximityNotification && proximityNotification.parentNode) {
        proximityNotification.classList.remove('show');
        proximityNotification.classList.add('hide');

        setTimeout(() => {
            if (proximityNotification && proximityNotification.parentNode) {
                proximityNotification.parentNode.removeChild(proximityNotification);
            }
            proximityNotification = null;
        }, 300);
    }
}