
let isVisible = true;
let currentHunger = 100;
let currentThirst = 100;

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'init' && data.module === 'metabolism') {
        if (data.data) {
            currentHunger = data.data.hunger || 100;
            currentThirst = data.data.thirst || 100;
            initializeMetabolism();
        }
        return;
    }

    if (data.action === 'update' && data.module === 'metabolism') {
        if (data.data) {
            if (data.data.hunger !== undefined) {
                currentHunger = data.data.hunger;
                updateBar('hunger', currentHunger)
            }

            if (data.data.thirst !== undefined) {
                currentThirst = data.data.thirst;
                updateBar('thirst', currentThirst)
            }
        }
        return;
    }

    if (data.action === 'show' && data.module === 'metabolism') {
        isVisible = true;
        const hudContainer = document.getElementById('metabolism-container');

        if (hudContainer) {
            hudContainer.style.display = 'block';
            hudContainer.style.opacity = '1';

            if (data.data) {
                if (data.data.hunger !== undefined) {
                    currentHunger = data.data.hunger;
                }
                if (data.data.thirst !== undefined) {
                    currentThirst = data.data.thirst;
                }
            }

            updateBar('hunger', currentHunger);
            updateBar('thirst', currentThirst);
        }
        return;
    }

    if (data.action === 'hide' && data.module === 'metabolism') {
        isVisible = false;
        const hudContainer = document.getElementById('metabolism-container');

        if (hudContainer) {
            hudContainer.style.display = 'none';
        }
        return;
    }
})

function initializeMetabolism() {
    isVisible = true;
    const hudContainer = document.getElementById('metabolism-container');

    if (hudContainer) {
        hudContainer.style.display = 'block';
        hudContainer.style.opacity = 1;

        updateBar('hunger', currentHunger)
        updateBar('thirst', currentThirst)
    } else {
        console.error('Element metabolism-container non trouvé dans le DOM')
    }
}

function updateBar(type, value) {
    const bar = document.getElementById(`${type}-bar`);

    if (!bar) {
        console.error(`Element ${type}-bar non trouvé dans le DOM`)
        return;
    }

    bar.style.height = value + '%';

    if (value <= 20) {
        bar.classList.add('low');
    } else {
        bar.classList.remove('low');
    }
}