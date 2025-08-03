class SimpleUILoader {
    constructor() {
        this.activeModules = new Map();
        this.persistentModules = new Map();
        this.contentContainer = document.getElementById('ui-content');
        this.baseZIndex = 1001;
        this.currentZIndex = this.baseZIndex;
        this.init();
        this.loadPersistentModules();
    }

    init() {
        window.addEventListener('message', (event) => {
            const data = event.data;
            console.log('[UI Loader] Message reçu:', JSON.stringify(data));

            switch (data.action) {
                case 'loadUI':
                    this.loadUI(data.module, data.data);
                    break;
                case 'closeUI':
                    this.closeUI(data.module);
                    break;
                case 'updateUI':
                    this.updateUI(data.module, data.data);
                    break;
                case 'bringToFront':
                    this.bringToFront(data.module);
                    break;
                case 'setPriority':
                    this.setModulePriority(data.module, data.priority);
                    break;
                case 'showModule':
                    this.showModule(data.module, data.data);
                    break;
                case 'hideModule':
                    this.hideModule(data.module);
                    break;
                case 'toggleModule':
                    this.toggleModule(data.module, data.data);
                    break;
            }
        });
    }

    async loadUI(module, data = {}) {
        console.log(`[UI Loader] Chargement de l'UI: ${module}`);

        // Vérifier si c'est un module persistant déjà chargé
        if (this.isPersistentModule(module) && this.persistentModules.has(module)) {
            this.showModule(module, data);
            return;
        }

        // Vérifier si c'est un module normal déjà actif
        if (this.activeModules.has(module)) {
            this.updateUI(module, data);
            this.bringToFront(module);
            return;
        }

        try {
            const htmlPath = this.getModulePath(module);

            const response = await fetch(htmlPath);

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const htmlContent = await response.text();

            const moduleContainer = document.createElement('div');
            moduleContainer.id = `module-${module}`;
            moduleContainer.className = 'ui-module';

            // Vérifier si c'est un module persistant
            const isPersistent = this.isPersistentModule(module);
            if (isPersistent) {
                moduleContainer.classList.add('persistent');
            }

            // Ajouter la priorité du module
            const modulePriority = this.getModulePriority(module);
            moduleContainer.classList.add(`priority-${modulePriority}`);

            // Assigner un z-index unique pour ce module
            const moduleZIndex = this.getNextZIndex(module);
            moduleContainer.style.zIndex = moduleZIndex;

            moduleContainer.innerHTML = htmlContent;

            // Ajouter directement au body pour une indépendance totale
            document.body.appendChild(moduleContainer);

            // Charger et exécuter le CSS du module
            await this.loadModuleCSS(module);

            // Charger et exécuter le JS du module
            await this.loadModuleJS(module);

            // Ajouter l'animation d'apparition
            setTimeout(() => {
                moduleContainer.classList.add('loaded');
            }, 50);

            // Ajouter un event listener pour mettre au premier plan au clic (sauf pour les modules persistants cachés)
            if (!isPersistent) {
                moduleContainer.addEventListener('mousedown', () => {
                    this.bringToFront(module);
                });
            }

            const moduleData = {
                container: moduleContainer,
                data: data,
                loadedAt: Date.now(),
                zIndex: moduleZIndex,
                priority: modulePriority,
                visible: true
            };

            // Stocker le module selon son type
            if (isPersistent) {
                this.persistentModules.set(module, moduleData);
                // Les modules persistants commencent visibles par défaut
                moduleContainer.classList.add('visible');
            } else {
                this.activeModules.set(module, moduleData);
            }

            // Envoyer les données au script du module après un court délai
            setTimeout(() => {
                window.postMessage({
                    action: 'init',
                    module: module,
                    data: data
                }, '*');
            }, 100);

            console.log(`Module ${module} chargé avec succès avec z-index: ${moduleZIndex}`);
        } catch (error) {
            console.error(`[UI Loader] Erreur lors du chargement de ${module}:`, error);
        }
    }

    async loadModuleCSS(module) {
        const cssPath = `${this.getModuleBasePath(module)}/style.css`;

        // Supprimer l'ancien CSS du module s'il existe
        const oldStyle = document.querySelector(`#${module}-style`);
        if (oldStyle) {
            oldStyle.remove();
        }

        try {
            const response = await fetch(cssPath);
            const cssContent = await response.text();

            const styleElement = document.createElement('style');
            styleElement.id = `${module}-style`;
            styleElement.textContent = cssContent;
            document.head.appendChild(styleElement);
        } catch (error) {
            console.warn(`[UI Loader] CSS non trouvé pour ${module}`);
        }
    }

    async loadModuleJS(module) {
        const jsPath = `${this.getModuleBasePath(module)}/script.js`;

        // Supprimer l'ancien script du module s'il existe
        const oldScript = document.querySelector(`#${module}-script`);
        if (oldScript) {
            oldScript.remove();
        }

        try {
            const response = await fetch(jsPath);
            const jsContent = await response.text();

            // Créer un script avec un namespace pour éviter les conflits
            const scriptContent = `
                (function() {
                    const MODULE_NAME = '${module}';
                    const MODULE_CONTAINER = document.getElementById('module-${module}');

                    ${jsContent}
                })();
            `;

            const scriptElement = document.createElement('script');
            scriptElement.id = `${module}-script`;
            scriptElement.textContent = scriptContent;
            document.head.appendChild(scriptElement);
        } catch (error) {
            console.warn(`[UI Loader] JavaScript non trouvé pour ${module}`);
        }
    }

    closeUI(module = null) {
        if (module) {
            // Ne pas fermer les modules persistants, les cacher seulement
            if (this.isPersistentModule(module)) {
                this.hideModule(module);
                return;
            }

            if (!this.activeModules.has(module)) {
                console.warn(`Module ${module} n'est pas actif`);
                return;
            }

            console.log(`[UI Loader] Fermeture de l'UI: ${module}`);

            const moduleData = this.activeModules.get(module);

            if (moduleData.container) {
                // Animation de fermeture
                moduleData.container.style.opacity = '0';
                setTimeout(() => {
                    moduleData.container.remove();
                }, 300);
            }

            this.removeModuleAssets(module);
            this.activeModules.delete(module);
        }
    }

    updateUI(module, data) {
        const moduleData = this.getModuleData(module);
        if (!moduleData) {
            console.warn(`Impossible de mettre à jour ${module}, module non trouvé`);
            return;
        }

        moduleData.data = { ...moduleData.data, ...data };

        // Mettre à jour dans la bonne Map
        if (this.isPersistentModule(module)) {
            this.persistentModules.set(module, moduleData);
        } else {
            this.activeModules.set(module, moduleData);
        }

        // Relayer la mise à jour au module actif
        window.postMessage({
            action: 'update',
            module: module,
            data: data
        }, '*');
    }

    showModule(module, data = null) {
        if (!this.isPersistentModule(module)) {
            console.warn(`${module} n'est pas un module persistant`);
            return;
        }

        if (!this.persistentModules.has(module)) {
            console.warn(`Module persistant ${module} non chargé`);
            return;
        }

        const moduleData = this.persistentModules.get(module);

        // Mettre à jour les données si fournies
        if (data) {
            moduleData.data = { ...moduleData.data, ...data };
            this.persistentModules.set(module, moduleData);
        }

        moduleData.container.classList.remove('hidden');
        moduleData.container.classList.add('visible');
        moduleData.visible = true;

        // Ajouter l'event listener pour le focus si pas déjà présent
        if (!moduleData.container.hasAttribute('data-click-listener')) {
            moduleData.container.addEventListener('mousedown', () => {
                this.bringToFront(module);
            });
            moduleData.container.setAttribute('data-click-listener', 'true');
        }

        this.persistentModules.set(module, moduleData);

        // Envoyer l'événement de show au module
        window.postMessage({
            action: 'show',
            module: module,
            data: moduleData.data
        }, '*');

        console.log(`Module persistant ${module} affiché`);
    }

    hideModule(module) {
        print(`Tentative de cacher le module ${module}`)

        if (!this.isPersistentModule(module)) {
            console.warn(`${module} n'est pas un module persistant`);
            return;
        }

        if (!this.persistentModules.has(module)) {
            console.warn(`Module persistant ${module} non chargé`);
            return;
        }

        const moduleData = this.persistentModules.get(module);
        moduleData.container.classList.remove('visible');
        moduleData.container.classList.add('hidden');
        moduleData.visible = false;

        this.persistentModules.set(module, moduleData);

        // Envoyer l'événement de hide au module
        window.postMessage({
            action: 'hide',
            module: module
        }, '*');

        console.log(`Module persistant ${module} caché`);
    }

    toggleModule(module, data = null) {
        if (!this.isPersistentModule(module)) {
            console.warn(`${module} n'est pas un module persistant`);
            return;
        }

        if (!this.persistentModules.has(module)) {
            console.warn(`Module persistant ${module} non chargé`);
            return;
        }

        const moduleData = this.persistentModules.get(module);

        if (moduleData.visible) {
            this.hideModule(module);
        } else {
            this.showModule(module, data);
        }
    }

    async loadPersistentModules() {
        const persistentModules = this.getPersistentModules();

        console.log(`[UI Loader] Chargement des modules persistants:`, persistentModules);

        for (const module of persistentModules) {
            try {
                await this.loadUI(module, {});
                console.log(`Module persistant ${module} chargé`);
            } catch (error) {
                console.error(`Erreur lors du chargement du module persistant ${module}:`, error);
            }
        }
    }

    bringToFront(module) {
        const moduleData = this.getModuleData(module);
        if (!moduleData) {
            return;
        }

        const newZIndex = ++this.currentZIndex;

        moduleData.container.style.zIndex = newZIndex;
        moduleData.zIndex = newZIndex;

        // Mettre à jour dans la bonne Map
        if (this.isPersistentModule(module)) {
            this.persistentModules.set(module, moduleData);
        } else {
            this.activeModules.set(module, moduleData);
        }

        console.log(`Module ${module} mis au premier plan avec z-index: ${newZIndex}`);
    }

    setModulePriority(module, priority) {
        const moduleData = this.getModuleData(module);
        if (!moduleData) {
            return;
        }

        const validPriorities = ['low', 'normal', 'high', 'critical'];

        if (!validPriorities.includes(priority)) {
            console.warn(`Priorité invalide: ${priority}`);
            return;
        }

        // Supprimer l'ancienne classe de priorité
        moduleData.container.classList.remove(`priority-${moduleData.priority}`);

        // Ajouter la nouvelle classe de priorité
        moduleData.container.classList.add(`priority-${priority}`);

        moduleData.priority = priority;

        // Mettre à jour dans la bonne Map
        if (this.isPersistentModule(module)) {
            this.persistentModules.set(module, moduleData);
        } else {
            this.activeModules.set(module, moduleData);
        }

        console.log(`Priorité du module ${module} changée pour: ${priority}`);
    }

    removeModuleAssets(module) {
        const moduleStyle = document.querySelector(`#${module}-style`);
        const moduleScript = document.querySelector(`#${module}-script`);

        if (moduleStyle) moduleStyle.remove();
        if (moduleScript) moduleScript.remove();
    }

    getNextZIndex(module) {
        const priority = this.getModulePriority(module);
        const baseZIndexes = {
            'low': 1001,
            'normal': 1010,
            'high': 1020,
            'critical': 1030
        };

        return baseZIndexes[priority] + this.activeModules.size;
    }

    getModulePriority(module) {
        const modulePriorities = {
            'coma': 'critical',
            'inventory': 'critical',
            'character': 'normal',
            'banking': 'normal',
            'admin': 'normal',
            'notify': 'low',
            'metabolism': 'low'
        };

        return modulePriorities[module] || 'normal';
    }

    getPersistentModules() {
        // Liste des modules qui doivent être chargés de manière persistante
        return ['metabolism', 'notify'];
    }

    isPersistentModule(module) {
        return this.getPersistentModules().includes(module);
    }

    getModulePath(module) {
        return `${this.getModuleBasePath(module)}/index.html`;
    }

    getModuleBasePath(module) {
        const modulePaths = {
            'coma': '../r_coma/html',
            'inventory': '../r_inventory/html',
            'character': '../r_char/html',
            'notify': '../r_notify/html',
            'metabolism': '../r_metabolism/html',
            'banking': '../r_banking/html',
            'admin': '../r_admin/html'
        };

        return modulePaths[module] || `r_${module}/html`;
    }

    // Méthodes utilitaires pour l'API externe
    getActiveModules() {
        return Array.from(this.activeModules.keys());
    }

    getPersistentModulesList() {
        return Array.from(this.persistentModules.keys());
    }

    getAllModules() {
        return [...this.getActiveModules(), ...this.getPersistentModulesList()];
    }

    isModuleActive(module) {
        return this.activeModules.has(module) || this.persistentModules.has(module);
    }

    isModuleVisible(module) {
        const moduleData = this.getModuleData(module);
        return moduleData ? moduleData.visible !== false : false;
    }

    getModuleData(module) {
        return this.activeModules.get(module) || this.persistentModules.get(module) || null;
    }
}

// Initialiser le loader
const uiLoader = new SimpleUILoader();

// Exposer l'API globalement pour un accès externe
window.UILoader = {
    load: (module, data) => uiLoader.loadUI(module, data),
    close: (module) => uiLoader.closeUI(module),
    update: (module, data) => uiLoader.updateUI(module, data),
    show: (module, data) => uiLoader.showModule(module, data),
    hide: (module) => uiLoader.hideModule(module),
    toggle: (module, data) => uiLoader.toggleModule(module, data),
    bringToFront: (module) => uiLoader.bringToFront(module),
    setPriority: (module, priority) => uiLoader.setModulePriority(module, priority),
    getActive: () => uiLoader.getActiveModules(),
    getPersistent: () => uiLoader.getPersistentModulesList(),
    getAll: () => uiLoader.getAllModules(),
    isActive: (module) => uiLoader.isModuleActive(module),
    isVisible: (module) => uiLoader.isModuleVisible(module),
    getData: (module) => uiLoader.getModuleData(module)?.data || null,
    isPersistent: (module) => uiLoader.isPersistentModule(module)
};