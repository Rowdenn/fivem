let currentCharacter = {};
let isEditingChestHair = false;

function formatDate(string) {
    if (!string) return "";

    const date = new Date(string);
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();

    return `${day}/${month}/${year}`;
}

function updateCharacterValue(element) {
    const key = element.id;
    let value

    if (element.type === 'range') {
        value = parseFloat(element.value)
    } else if (element.type === 'text') {
        value = element.value
    } else if (element.type === 'date') {
        value = formatDate(element.value)
    } else {
        value = parseInt(element.value)
    }
    
    currentCharacter[key] = value;
    
    const valueSpan = document.getElementById(key + '_value');
    if (valueSpan) {
        valueSpan.textContent = value;
    }

    const showChest = (key == 'chest_hair' || key == 'chest_hair_color');
    
    fetch('https://r_char/updateCharacter', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            ...currentCharacter,
            showChest: showChest
        })
    });
}

function updateUI() {
    Object.keys(currentCharacter).forEach(key => {
        const element = document.getElementById(key);
        if (element) {
            element.value = currentCharacter[key];
            
            const valueSpan = document.getElementById(key + '_value');
            if (valueSpan) {
                valueSpan.textContent = currentCharacter[key];
            }
        }
    });
}

function initializeCreator() {
    const inputs = document.querySelectorAll('input[type="range"], input[type="text"], input[type="date"], select');
    inputs.forEach(input => {
        input.addEventListener('input', function() {
            updateCharacterValue(this);
        });
        
        const valueSpan = document.getElementById(input.id + '_value');
        if (valueSpan) {
            valueSpan.textContent = input.value;
        }
    });
    
    document.getElementById('save-btn').addEventListener('click', function() {
        fetch('https://r_char/finishCreation', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(currentCharacter)
        });
    });
    
    document.getElementById('cancel-btn').addEventListener('click', function() {
        fetch('https://r_char/cancelCreation', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({})
        });
    });
}

window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'openCreator':
            document.getElementById('character-creator').classList.remove('hidden');
            if (data.character) {
                currentCharacter = data.character;
                updateUI();
            }
            break;
            
        case 'closeCreator':
            document.getElementById('character-creator').classList.add('hidden');
            break;
    }
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        fetch('https://r_char/cancelCreation', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({})
        });
    }
});

document.addEventListener('DOMContentLoaded', initializeCreator());

function showTab(tabName) {
    const tabContents = document.querySelectorAll('.tab-content');
    tabContents.forEach(tab => tab.classList.remove('active'));
    
    const tabButtons = document.querySelectorAll('.tab-button');
    tabButtons.forEach(button => button.classList.remove('active'));
    
    document.getElementById(tabName).classList.add('active');
    
    event.target.classList.add('active');
}

let currentZoom = 0.0;
const maxZoom = 1.0;
const minZoom = 0.0;
const zoomStep = 0.05;

function isInNoZoomZone(element) {
    const noZoomSelectors = [
        '.creator-panel',
        '.tab-content',
        '.section',
        '.silder-group',
        '.tabs',
        '.buttons',
        'input',
        'select',
        'button',
        'label',
        'h2',
        'h3'
    ];

    let currentElement = element;
    while (currentElement && currentElement !== document.body) {
        for (let selector of noZoomSelectors) {
            if (currentElement.matches && currentElement.matches(selector)) {
                return true;
            }
        }
        currentElement = currentElement.parentElement;
    }

    return false;
}

document.addEventListener('wheel', function(event) {
    if (isInNoZoomZone(event.target)) {
        return;
    }

    if (event.deltaY < 0) {
        currentZoom = Math.min(maxZoom, currentZoom + zoomStep);
    } else {
        currentZoom = Math.max(minZoom, currentZoom - zoomStep);
    }
    
    fetch(`https://${GetParentResourceName()}/updateZoom`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            zoom: currentZoom
        })
    });
});

let currentRotation = 0;
const rotationStep = 90;

function rotatePlayer(direction) {
    let newRotation = currentRotation

    switch(direction) {
        case 'left':
            newRotation = currentRotation - rotationStep
            break;
        case 'right':
            newRotation = currentRotation + rotationStep
            break;
        case 'front':
            newRotation = 0
            break;
        case 'back':
            newRotation = 180
            break;
    }

    if (newRotation < 0) {
        newRotation += 360;
    } else if (newRotation >= 360) {
        newRotation -= 360;
    }

    currentRotation = newRotation;

    fetch(`https://${GetParentResourceName()}/rotatePlayer`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            direction: direction
        })
    });
}

document.addEventListener('keydown', function(event) {
    if (isInNoZoomZone(event.target)) {
        return
    }

    switch(event.key) {
        case 'ArrowLeft':
        case 'q':
        case 'Q':
            event.preventDefault();
            rotatePlayer('left');
            break;

        case 'ArrowRight':
        case 'd':
        case 'D':
            event.preventDefault();
            rotatePlayer('right');
            break;

        case 'ArrowUp':
        case 'z':
        case 'Z':
            event.preventDefault();
            rotatePlayer('back');
            break;

        case 'ArrowDown':
        case 's':
        case 'S':
            event.preventDefault();
            rotatePlayer('front');
            break;
    }
})