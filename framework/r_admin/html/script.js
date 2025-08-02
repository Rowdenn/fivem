window.addEventListener('message', function (event) {
    if (event.data.type === 'clipboard') {
        const input = document.getElementById('clipboard');
        input.value = event.data.text;
        input.select();
        input.setSelectionRange(0, 99999);

        try {
            document.execCommand('copy');
        } catch (err) {
            console.error('Erreur lors de la copie:', err);
        }
    }
});