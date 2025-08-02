let notificationCount = 0;
let notifications = [];
const maxNotifications = 10;

window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'showNotification':
            showNotification(data.data);
            break;
    }
});

function showNotification(data) {
    if (notifications.length >= maxNotifications) {
        removeOldestNotification();
    }

    const notification = createNotificationElement(data);
    const container = document.getElementById('notification-container');

    container.appendChild(notification);
    notifications.push(notification);

    setTimeout(() => {
        notification.classList.add('show');
    }, 100);

    const progressBar = notification.querySelector('.notification-bar');
    if(progressBar) {
        progressBar.style.width = '100%';
        setTimeout(() => {
            progressBar.style.width = '0%';
            progressBar.transitionDuration = `${data.duration}ms`
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
        <div class ="notification-content">
            <p class="notification-message">${data.message}</p>
        </div>
        <div class="notification-progress"></div>
    `;

    return notification
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
    notification.forEach(notification => {
        removeNotification(notification);
    })
    notification = [];
}