
let isVisible = true;

window.addEventListener('message', function (event) {
    const data = event.data;

    switch (data.type) {
        case 'updateValues':
            if (isVisible) {
                updateBar('hunger', data.hunger);
                updateBar('thirst', data.thirst);
            }
            break;
        case 'toggleVisibility':
            toggleHudVisibility(data.show)
            break;
    }
})

function updateBar(type, value) {
    const bar = document.getElementById(`${type}-bar`);
    bar.style.height = value + '%';

    if (value <= 20) {
        bar.classList.add('low');
    } else {
        bar.classList.remove('low');
    }
}

function toggleHudVisibility(show) {
    isVisible = show;
    const hudContainer = document.getElementById('metabolism-container');

    if (!hudContainer) return;

    if (show) {
        hudContainer.style.display = 'block';
        hudContainer.style.transition = 'opacity 0.3s ease-in-out';
        setTimeout(() => {
            hudContainer.style.opacity = '1';
        }, 10)
    } else {
        hudContainer.style.transition = 'opacity 0.3s ease-in-out';
        hudContainer.style.opacity = '0';
        setTimeout(() => {
            hudContainer.style.display = 'none';
        }, 300)
    }
}