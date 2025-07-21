let inventoryOpen = false;
let selectedSlot = null;
let playerInventory = [];
let groundItems = [];
let clickTimeout = null;
let clickCount = 0;
let lastClickTime = 0;
let isDragStarted = false;
let dragStartPosition = { x: 0, y: 0 }
const DRAG_THRESHOLD = 5;
let groundItemsForInventory = [];
let allGroundItems = [];

window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'openInventory':
            openInventory(data);
            break;
        case 'closeInventory':
            closeInventory();   
            break;
        case 'updateInventory':
            updateInventory(data.inventory);
            break;
        case 'updateGroundItems':
            updateGroundItems(data.groundItems);
            break;
        case 'updatePlayerData':
            updatePlayerInfo(data.playerData);
            break;
        case 'addGroundItem':
            addGroundItem(data.groundItem);
            break;
        case 'updateGroundItems':
            updateGroundItems(data.groundItems);
            break;
    }
});

// ! EXEMPLE POUR REFRESH LE PERSO APRES UNE ACTION
function onItemEquipped() {
    // Après avoir équipé un item, rafraîchir l'affichage
    setTimeout(() => {
        refreshCharacterDisplay();
    }, 500);
}

function openInventory(data = {}) {
    // Nettoyer d'abord tout état de drag précédent
    cleanupDrag();
    
    inventoryOpen = true;
    
    document.getElementById('inventory-container').classList.remove('hidden');

    refreshCharacterDisplay();

    generateInventorySlots();
    generateGroundSlots();
    
    // Setup le drag and drop APRÈS avoir généré les slots
    setupDragAndDrop();
}

function closeInventory() {
    inventoryOpen = false;
    
    // Cleanup complet du drag avant de fermer
    cleanupDrag();
    
    // Supprimer tous les event listeners de drag
    document.removeEventListener('mousedown', handleMouseDown);
    document.removeEventListener('mousemove', handleMouseMove);
    document.removeEventListener('mouseup', handleMouseUp);
    document.removeEventListener('dragstart', preventDragStart);
    
    // Nettoyer tous les éléments de drag qui pourraient rester
    document.querySelectorAll('.drag-preview').forEach(el => {
        if (el.parentNode) {
            document.body.removeChild(el);
        }
    });
    
    document.querySelectorAll('.dragging').forEach(el => {
        el.classList.remove('dragging');
        el.style.transform = '';
        el.style.opacity = '';
        el.style.transition = '';
    });
    
    document.querySelectorAll('.drag-over').forEach(el => {
        el.classList.remove('drag-over');
    });
    
    // Restaurer les styles du body
    document.body.style.cursor = 'default';
    document.body.style.userSelect = 'auto';
    
    // Fermer l'inventaire
    document.getElementById('inventory-container').classList.add('hidden');
    selectedSlot = null;
    draggedItem = null;
    updateItemInfo(null);
    
    // Réinitialiser les variables de drag
    isDragging = false;
    dragElement = null;
    dragPreview = null;
    draggedItem = null;
    animationFrameId = null;
    mousePosition = { x: 0, y: 0 };
    dragOffset = { x: 0, y: 0 };
}

function generateInventorySlots() {
    const playerGrid = document.getElementById('player-grid');
    playerGrid.innerHTML = '';
    
    for (let i = 1; i <= 120; i++) {
        const slot = document.createElement('div');
        slot.className = 'inventory-slot';
        slot.dataset.slot = i;
        slot.dataset.type = 'player';
        
        // Set les 5 premiers slots en tant que quick slots
        if (i <= 5) {
            slot.classList.add('quick-slot');
            slot.dataset.key = i;
        }
        
        slot.addEventListener('click', () => selectSlot(i, 'player'));
        playerGrid.appendChild(slot);
    }
}

function generateGroundSlots(item, index) {
    const groundGrid = document.getElementById('ground-grid');
    groundGrid.innerHTML = '';
    
    // Générer les slots pour les items au sol
    for (let i = 1; i <= 50; i++) {
        const slot = document.createElement('div');
        slot.className = 'inventory-slot';
        slot.dataset.slot = i;
        slot.dataset.type = 'ground';

        slot.addEventListener('click', () => selectSlot(i, 'ground'));
        groundGrid.appendChild(slot);
    }

    updateGroundSlots();
}

function updatePlayerSlots() {
    const playerGrid = document.getElementById('player-grid');
    if (!playerGrid) return;
    
    const slots = playerGrid.querySelectorAll('.inventory-slot');
    slots.forEach(slot => {
        slot.innerHTML = '';
        slot.classList.remove('has-item');
        slot.removeAttribute('data-item');
        slot.removeAttribute('data-count');
        slot.style.cursor = 'default';
    });
    
    playerInventory.forEach(item => {
        const slot = playerGrid.querySelector(`[data-slot="${item.slot}"]`);
        if (slot) {
            slot.classList.add('has-item');
            slot.setAttribute('data-item', item.item);
            slot.setAttribute('data-count', item.count);
            slot.style.cursor = 'grab';
            
            const itemImg = document.createElement('img');
            if (item.image) {
                itemImg.src = `data:image/png;base64,${item.image}`;
            } else {
                itemImg.src = 'https://placehold.co/48x48';
            }
            itemImg.alt = item.label || item.item;
            itemImg.style.pointerEvents = 'none';
            itemImg.onerror = function() {
                this.src = 'https://placehold.co/48x48';
            };
            
            const itemCount = document.createElement('span');
            itemCount.className = 'item-count';
            itemCount.textContent = item.count > 1 ? item.count : '';
            itemCount.style.pointerEvents = 'none';
            
            slot.appendChild(itemImg);
            slot.appendChild(itemCount);
        }
    });
}

function updateGroundSlots() {
    const groundGrid = document.getElementById('ground-grid');
    if (!groundGrid) return;

    groundGrid.innerHTML = '';
    
    // Utiliser les items proches pour l'inventaire
    groundItemsForInventory.forEach((item, index) => {
        const slot = document.createElement('div');
        slot.className = 'inventory-slot ground-slot has-item';
        slot.dataset.slot = index + 1;
        slot.dataset.type = 'ground';
        slot.dataset.item = item.item;
        slot.dataset.count = item.count;
        slot.dataset.groundId = item.id;

        const itemImage = document.createElement('img');
        itemImage.src = `images/${item.image}`;
        itemImage.alt = item.label || item.item;
        itemImage.className = 'item-image';

        const itemCount = document.createElement('span');
        itemCount.className = 'item-count';
        itemCount.textContent = item.count > 1 ? item.count : '';

        slot.appendChild(itemImage);
        slot.appendChild(itemCount);
        groundGrid.appendChild(slot);
    });
}

function selectSlot(slotNumber, type) {
    if (selectedSlot) {
        selectedSlot.element.classList.remove('selected');
    }
    
    const slotElement = document.querySelector(`#${type}-grid [data-slot="${slotNumber}"]`);
    if (slotElement) {
        slotElement.classList.add('selected');
        
        selectedSlot = {
            number: slotNumber,
            type: type,
            element: slotElement
        };
        
        slotElement.style.transform = 'scale(1.05)';
        setTimeout(() => {
            slotElement.style.transform = 'scale(1)';
        }, 200);
        
        let itemData = null;
        if (type === 'player') {
            itemData = playerInventory.find(item => item.slot === slotNumber);
        } else {
            itemData = groundItems[slotNumber - 1];
        }
        
        updateItemInfo(itemData);
    }
}

function updateItemInfo(itemData) {
    const itemInfo = document.getElementById('item-info');
    const useBtn = document.getElementById('use-item');
    const giveBtn = document.getElementById('give-item');
    
    if (itemData) {
        itemInfo.classList.add('active');
        
        document.getElementById('item-name').textContent = itemData.label || itemData.item;
        document.getElementById('item-description').textContent = itemData.description || 'Aucune description';
        document.getElementById('item-weight').textContent = `Poids: ${itemData.weight || 0}kg`;
        document.getElementById('item-count').textContent = `Quantité: ${itemData.count || 1}`;
        
        const itemImg = document.getElementById('item-img');
        
        // Utiliser l'image de la base de données
        if (itemData.image) {
            itemImg.src = `data:image/png;base64,${itemData.image}`;
        } else {
            // Image par défaut si pas d'image en base
            itemImg.src = 'https://placehold.co/64x64';
        }
        
        itemImg.alt = itemData.label || itemData.item;
        itemImg.onerror = function() {
            this.src = 'https://placehold.co/64x64';
        };
        
        useBtn.classList.add('active');
        giveBtn.classList.add('active');
    } else {
        itemInfo.classList.remove('active');
        
        useBtn.classList.remove('active');
        giveBtn.classList.remove('active');
    }
}

function addGroundItem(newItem) {
    console.log("Nouvel item ajouté au sol : ", newItem);

    const existingIndex = groundItems.findIndex(item => item.id === newItem.id);

    if (existingIndex === -1) {
        groundItems.push(newItem)

        if (inventoryOpen) {
            updateGroundSlots();
        }

        console.log(`Item ${newItem.label || newItem.item} ajouté au sol`)
    } else {
        error.log('Item déjà présent, ignoré')
    }
}

function removeGroundItem(itemId) {
    const itemIndex = groundItems.findIndex(item => item.id === itemId);

    if (itemIndex !== -1) {
        groundItems.splice(itemIndex, 1);

        if (inventoryOpen) {
            updateGroundSlots();
        }

        console.log(`Item ${itemId} supprimé du sol`)
    }
}
 
function updatePlayerInfo(playerData) {
    const currentWeight = document.getElementById('current-weight');
    const maxWeight = document.getElementById('max-weight');
    
    if (currentWeight) currentWeight.textContent = playerData.weight || 0;
    if (maxWeight) maxWeight.textContent = playerData.maxWeight || 50;
}

function updateInventory(inventory) {   
    playerInventory = inventory;
    
    const playerGrid = document.getElementById('player-grid');
    if (playerGrid) {
        playerGrid.style.opacity = '0.5';
        
        setTimeout(() => {
            updatePlayerSlots();
            playerGrid.style.opacity = '1';
        }, 100);
    }
}

function updateGroundItems(items) {
    groundItemsForInventory = items;
    
    // Mettre à jour seulement si l'inventaire est ouvert
    if (inventoryOpen) {
        updateGroundSlots();
    }
}

// Variables pour le drag optimisé
let isDragging = false;
let dragElement = null;
let dragPreview = null;
let dragOffset = { x: 0, y: 0 };
let draggedItem = null;
let animationFrameId = null;
let mousePosition = { x: 0, y: 0 };

function setupDragAndDrop() {
    document.removeEventListener('mousedown', handleMouseDown);
    document.removeEventListener('mousemove', handleMouseMove);
    document.removeEventListener('mouseup', handleMouseUp);
    document.removeEventListener('dragstart', preventDragStart);

    document.addEventListener('mousedown', handleMouseDown);
    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
    document.addEventListener('dragstart', preventDragStart);
}

function handleMouseDown(e) {
    const slot = e.target.closest('.inventory-slot');
    if (slot && slot.classList.contains('has-item')) {
        e.preventDefault();
        
        const currentTime = Date.now();
        const timeDiff = currentTime - lastClickTime;
        lastClickTime = currentTime;
        
        // Stocker la position initiale
        dragStartPosition.x = e.clientX;
        dragStartPosition.y = e.clientY;
        isDragStarted = false;
        
        // Gérer le double-clic (moins de 300ms entre les clics)
        if (timeDiff < 300) {
            clickCount++;
            if (clickCount === 2) {
                // C'est un double-clic - utiliser l'item
                handleDoubleClick(slot);
                clickCount = 0;
                return;
            }
        } else {
            clickCount = 1;
        }
        
        // Préparer le drag immédiatement (sans délai)
        prepareDrag(e, slot);
    }
}

function prepareDrag(e, slot) {
    // Préparer les données de drag
    draggedItem = {
        slot: parseInt(slot.dataset.slot),
        type: slot.dataset.type,
        element: slot,
        item: slot.dataset.item,
        count: parseInt(slot.dataset.count)
    };

    if (slot.dataset.type === 'ground' && slot.dataset.groundId) {
        draggedItem.id = parseInt(slot.dataset.groundId);
    }
    
    dragElement = slot;
    
    // Calculer l'offset de la souris par rapport au slot
    const rect = slot.getBoundingClientRect();
    dragOffset.x = e.clientX - rect.left;
    dragOffset.y = e.clientY - rect.top;
    
    // Ajouter un état de préparation
    slot.classList.add('drag-ready');
    document.body.style.userSelect = 'none';
}

function startDrag(e) {
    if (isDragStarted || !dragElement) return;
    
    isDragStarted = true;
    isDragging = true;
    clickCount = 0; // Annuler le double-clic si on commence à draguer
    
    // Supprimer l'état de préparation
    dragElement.classList.remove('drag-ready');
    
    // Créer un élément de prévisualisation
    createDragPreview(e);
    
    // Ajouter les classes CSS
    dragElement.classList.add('dragging');
    document.body.style.cursor = 'grabbing';
    
    // Démarrer l'animation frame
    startDragAnimation();
}

function handleDoubleClick(slot) {
    // Nettoyer tout état de drag
    cleanupDrag();
    
    // Utiliser l'item
    const slotNum = parseInt(slot.dataset.slot);
    const itemData = slot.dataset.type === 'player' ? 
        playerInventory.find(item => item.slot === slotNum) : 
        groundItems[slotNum - 1];
    
    if (itemData) {
        fetch(`https://${GetParentResourceName()}/useItem`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                slot: slotNum,
                item: itemData.item
            })
        });
    }
}

function handleMouseMove(e) {
    if (draggedItem && dragElement) {
        e.preventDefault();
        
        // Calculer la distance parcourue
        const distance = Math.sqrt(
            Math.pow(e.clientX - dragStartPosition.x, 2) + 
            Math.pow(e.clientY - dragStartPosition.y, 2)
        );
        
        // Si on dépasse le seuil et qu'on n'a pas encore commencé le drag
        if (distance > DRAG_THRESHOLD && !isDragStarted) {
            startDrag(e);
        }
        
        // Mettre à jour la position si le drag a commencé
        if (isDragStarted) {
            mousePosition.x = e.clientX;
            mousePosition.y = e.clientY;
        }
    }
}

function handleMouseUp(e) {
    // Annuler le timeout de clic s'il existe
    if (clickTimeout) {
        clearTimeout(clickTimeout);
        clickTimeout = null;
    }
    
    // Si on n'a pas bougé assez pour draguer, c'est un simple clic
    if (draggedItem && !isDragStarted) {
        // Attendre un peu pour voir si c'est un double-clic
        clickTimeout = setTimeout(() => {
            if (clickCount === 1) {
                console.log('Simple clic sur item');
            }
            cleanupDrag();
        }, 250);
        return;
    }
    
    if (isDragStarted && draggedItem) {
        e.preventDefault();
        
        // Trouver l'élément sous la souris
        const elementBelow = document.elementFromPoint(e.clientX, e.clientY);
        const targetSlot = elementBelow ? elementBelow.closest('.inventory-slot') : null;
        
        if (targetSlot && draggedItem && targetSlot !== dragElement) {
            const targetSlotNum = parseInt(targetSlot.dataset.slot);
            const targetType = targetSlot.dataset.type;
            
            console.log('Drag operation:', {
                from: draggedItem.type,
                to: targetType,
                sourceSlot: draggedItem.slot,
                targetSlot: targetSlotNum,
                groundId: draggedItem.id
            });
            
            // Vérifier si c'est pas le même slot
            if (draggedItem.slot !== targetSlotNum || draggedItem.type !== targetType) {
                // Animation de succès
                animateItemDrop(targetSlot, true);
                
                // Transfert du sol vers l'inventaire
                if (draggedItem.type === 'ground' && targetType === 'player') {
                    transferGroundToPlayer(draggedItem, targetSlot);
                }
                // Transfert de l'inventaire vers le sol
                else if (draggedItem.type === 'player' && targetType === 'ground') {
                    handleDropToGround(draggedItem, targetSlot);
                }
                // Déplacement dans l'inventaire
                else if (draggedItem.type === targetType) {
                    fetch(`https://${GetParentResourceName()}/moveItem`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            fromSlot: draggedItem.slot,
                            fromType: draggedItem.type,
                            toSlot: targetSlotNum,
                            toType: targetType,
                            item: draggedItem.item,
                            count: draggedItem.count
                        })
                    });
                }
                
                setTimeout(() => {
                    cleanupDrag();
                }, 200);
            } else {
                // Animation de retour
                animateItemDrop(dragElement, false);
                setTimeout(() => {
                    cleanupDrag();
                }, 200);
            }
        } else {
            // Si on drop en dehors d'un slot et que c'est un item du joueur
            if (draggedItem.type === 'player') {
                handleDropToGround(draggedItem);
            } else {
                // Animation de retour
                animateItemDrop(dragElement, false);
                setTimeout(() => {
                    cleanupDrag();
                }, 200);
            }
        }
    }
    
    cleanupDrag();
}

function handleTransfer(draggedItem, targetSlot) {
    const targetType = targetSlot.dataset.type;

    if (draggedItem.type === 'player' && targetType === 'ground') {
        handleDropToGround(draggedItem)
    } else if (draggedItem.type === 'ground' && targetType === 'player') {
        transferGroundToPlayer(draggedItem, targetSlot)
    }
}

function transferGroundToPlayer(draggedItem, targetSlot) {
    const targetSlotNum = parseInt(targetSlot.dataset.slot);
    
    console.log('Transfer data:', {
        draggedItem: draggedItem, // Debug complet
        groundItemId: draggedItem.id,
        toSlot: targetSlotNum,
        item: draggedItem.item
    });
    
    // Vérifier si l'ID existe
    if (!draggedItem.id) {
        console.error('ERREUR: groundItemId manquant!', draggedItem);
        return;
    }
    
    if (targetSlot.classList.contains('has-item')) {
        const targetItem = targetSlot.dataset.item;
        
        if (targetItem === draggedItem.item) {
            console.log('Stacking ground item...');
            fetch(`https://r_inventory/stackGroundToPlayer`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    groundItemId: parseInt(draggedItem.id),
                    toSlot: targetSlotNum,
                    count: parseInt(draggedItem.count)
                })
            });
        } else {
            console.log('Cannot stack different items');
        }
    } else {
        console.log('Picking up ground item...');
        fetch(`https://r_inventory/pickupItem`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                groundItemId: parseInt(draggedItem.id),
                toSlot: targetSlotNum
            })
        });
    }
}

function handleDropToGround(draggedItem) {
    fetch(`https://${GetParentResourceName()}/dropItem`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            slot: draggedItem.slot,
            item: draggedItem.item,
            count: draggedItem.count
        })
    })
}

function preventDragStart(e) {
    e.preventDefault();
}

function startDragAnimation() {
    function animate() {
        if (isDragging && dragPreview) {
            // Mise à jour fluide de la position
            const newX = mousePosition.x - dragOffset.x;
            const newY = mousePosition.y - dragOffset.y;
            
            // Utiliser transform pour de meilleures performances
            dragPreview.style.transform = `translate(${newX}px, ${newY}px) rotate(5deg)`;
            
            // Mettre en surbrillance le slot cible
            updateDragHighlight();
            
            // Continuer l'animation
            animationFrameId = requestAnimationFrame(animate);
        }
    }
    
    animationFrameId = requestAnimationFrame(animate);
}

function updateDragHighlight() {
    const elementBelow = document.elementFromPoint(mousePosition.x, mousePosition.y);
    const targetSlot = elementBelow ? elementBelow.closest('.inventory-slot') : null;
    
    // Supprimer les anciens highlights
    document.querySelectorAll('.drag-over').forEach(el => {
        el.classList.remove('drag-over');
    });
    
    // Ajouter le highlight au slot cible
    if (targetSlot && targetSlot !== dragElement) {
        targetSlot.classList.add('drag-over');
    }
}

function createDragPreview(e) {
    // Supprimer toute prévisualisation existante
    if (dragPreview) {
        if (dragPreview.parentNode) {
            document.body.removeChild(dragPreview);
        }
        dragPreview = null;
    }
    
    if (dragElement) {
        dragPreview = dragElement.cloneNode(true);
        dragPreview.classList.add('drag-preview');
        dragPreview.classList.remove('dragging'); // Enlever la classe dragging du clone
        
        // Styles optimisés pour les performances
        Object.assign(dragPreview.style, {
            position: 'fixed',
            pointerEvents: 'none',
            zIndex: '9999',
            opacity: '0.8',
            width: '50px',
            height: '50px',
            left: '0px',
            top: '0px',
            transform: `translate(${e.clientX - dragOffset.x}px, ${e.clientY - dragOffset.y}px) rotate(5deg)`,
            transition: 'none',
            willChange: 'transform'
        });
        
        document.body.appendChild(dragPreview);
    }
}

function animateItemDrop(targetElement, success) {
    if (!dragPreview || !targetElement) return;
    
    const targetRect = targetElement.getBoundingClientRect();
    const targetX = targetRect.left + targetRect.width / 2 - 25;
    const targetY = targetRect.top + targetRect.height / 2 - 25;
    
    // Animation fluide vers la cible
    dragPreview.style.transition = 'transform 0.2s ease-out, opacity 0.2s ease-out';
    dragPreview.style.transform = `translate(${targetX}px, ${targetY}px) rotate(0deg) scale(${success ? 1.1 : 0.9})`;
    dragPreview.style.opacity = success ? '1' : '0.3';
    
    // Effet visuel sur le slot cible
    if (success) {
        targetElement.classList.add('drop-success');
        setTimeout(() => {
            targetElement.classList.remove('drop-success');
        }, 300);
    }
}

function cleanupDrag() {
    isDragging = false;
    isDragStarted = false;
    
    // Annuler les timeouts
    if (clickTimeout) {
        clearTimeout(clickTimeout);
        clickTimeout = null;
    }
    
    // Annule l'animation frame
    if (animationFrameId) {
        cancelAnimationFrame(animationFrameId);
        animationFrameId = null;
    }
    
    // Nettoyer l'élément dragué
    if (dragElement) {
        dragElement.classList.remove('dragging', 'drag-ready');
        dragElement.style.transform = '';
        dragElement.style.opacity = '';
        dragElement.style.transition = '';
    }
    
    // Nettoyer la prévisualisation
    if (dragPreview) {
        dragPreview.style.transition = 'opacity 0.1s ease-out';
        dragPreview.style.opacity = '0';

        setTimeout(() => {
            if (dragPreview && dragPreview.parentNode) {
                document.body.removeChild(dragPreview);
            }
            dragPreview = null;
        }, 100);
    }
    
    // Nettoyer tous les éléments drag-preview orphelins
    document.querySelectorAll('.drag-preview').forEach(el => {
        if (el.parentNode) {
            document.body.removeChild(el);
        }
    });
    
    // Nettoyer tous les indicateurs visuels
    document.querySelectorAll('.drag-over').forEach(el => {
        el.classList.remove('drag-over');
    });
    
    document.querySelectorAll('.drop-success').forEach(el => {
        el.classList.remove('drop-success');
    });
    
    document.querySelectorAll('.dragging, .drag-ready').forEach(el => {
        el.classList.remove('dragging', 'drag-ready');
        el.style.transform = '';
        el.style.opacity = '';
        el.style.transition = '';
    });
    
    // Restaurer les styles du body
    document.body.style.cursor = 'default';
    document.body.style.userSelect = 'auto';
    
    // Réinitialiser les variables
    draggedItem = null;
    dragElement = null;
    mousePosition = { x: 0, y: 0 };
    dragOffset = { x: 0, y: 0 };
    clickCount = 0;
    lastClickTime = 0;
    dragStartPosition = { x: 0, y: 0 };
}

function updatePlayerInfo(playerData) {
    document.getElementById('current-weight').textContent = playerData.weight || 0;
    document.getElementById('max-weight').textContent = playerData.maxWeight || 50;
}

function refreshCharacterDisplay() {
    fetch(`https://${GetParentResourceName()}/updateCharacterDisplay`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Gestionnaire d'événements pour les boutons
document.addEventListener('DOMContentLoaded', function() {
    const useBtn = document.getElementById('use-item');
    if (useBtn) {
        useBtn.addEventListener('click', function() {
            if (selectedSlot && this.classList.contains('active')) {
                for (let i = 0; i < playerInventory.length; i++) {
                    if (playerInventory[i].slot == selectedSlot.number) {
                        fetch(`https://r_inventory/useItem`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                slot: selectedSlot.number,
                                item: playerInventory[i].item
                            })
                        })
                    }
                }
            };
        })
    }
    
    // Bouton Give Item
    const giveBtn = document.getElementById('give-item');
    if (giveBtn) {
        giveBtn.addEventListener('click', function() {
            if (selectedSlot && this.classList.contains('active')) {
                const itemData = selectedSlot.type === 'player' ? playerInventory[selectedSlot.number] : groundItems[selectedSlot.number];
                
                fetch(`https://${GetParentResourceName()}/giveItem`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        slot: selectedSlot.number,
                        item: itemData.item,
                        count: itemData.count
                    })
                })
            }
        });
    }
});

// Fermer l'inventaire avec Échap
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && inventoryOpen) {
        fetch(`https://${GetParentResourceName()}/closeInventory`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});