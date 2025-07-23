
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'updateValues':
            updateBar(data.hunger);
            updateBar(data.thirst);
            break;
    }
})

function updateBar(type, value) {
    const bar = document.getElementById(`${type}-bar`);
    bar.style.width = value + '%';

    if (value <= 20) {
        bar.classList.add('low');
    } else {
        bar.classList.remove('low');
    }
}
