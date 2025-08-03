window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'init' && data.module === 'admin') {
        if (data.data) {
            copyToClipboard(data.data.text);
        }
        return;
    }
});

function copyToClipboard(text) {
    const input = document.getElementById('clipboard');
    input.value = text;
    input.style.display = 'block';
    input.select();
    input.setSelectionRange(0, input.value.length);

    try {
        document.execCommand('copy');
    } catch (err) {
        console.error('Erreur lors de la copie (execCommand):', err);
    }
    input.style.display = 'none';
}