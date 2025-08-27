/**
 * UNIT3D Image Uploader
 * Reemplazo personalizado para imgbb.js
 * Compatible con la API existente pero usando nuestro propio servicio
 */

!(function () {
    var UNIT3DUploader = {
        // Configuración por defecto
        defaultSettings: {
            url: window.location.protocol + '//' + window.location.hostname + ':3002',
            vendor: 'unit3d',
            mode: 'auto',
            lang: 'es',
            autoInsert: 'bbcode-embed-full',
            palette: 'default',
            init: 'onload',
            containerClass: 'unit3d-uploader-container',
            buttonClass: 'unit3d-uploader-button',
            sibling: 0,
            siblingPos: 'after',
            fitEditor: 0,
            observe: 0,
            observeCache: 1,
            html: '<div class="%cClass"><button %x class="%bClass"><span class="%iClass">%iconSvg</span><span class="%tClass">%text</span></button></div>',
            css: '.%cClass{display:inline-block;margin-top:5px;margin-bottom:5px}.%bClass{line-height:normal;-webkit-transition:all .2s;-o-transition:all .2s;transition:all .2s;outline:0;color:#fff;border:none;cursor:pointer;background:linear-gradient(45deg,#667eea,#764ba2);border-radius:.5em;padding:.75em 1.5em;font-size:14px;font-weight:600;text-shadow:none;box-shadow:0 2px 10px rgba(0,0,0,0.1)}.%bClass:hover{background:linear-gradient(45deg,#764ba2,#667eea);transform:translateY(-1px);box-shadow:0 4px 15px rgba(0,0,0,0.2)}.%iClass,.%tClass{display:inline-block;vertical-align:middle}.%iClass svg{display:block;width:1em;height:1em;fill:currentColor}.%tClass{margin-left:.5em}'
        },

        // Namespace para atributos
        ns: {
            plugin: 'unit3d-uploader'
        },

        // Paletas de colores
        palettes: {
            default: ['#667eea', '#fff', '#764ba2', '#fff'],
            blue: ['#2980b9', '#fff', '#3498db', '#fff'],
            green: ['#27ae60', '#fff', '#2ecc71', '#fff'],
            purple: ['#8e44ad', '#fff', '#9b59b6', '#fff']
        },

        // Propiedades de clase
        classProps: ['button', 'container'],

        // Icono SVG personalizado
        iconSvg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z"/><path d="M8,12V14H16V12H8M8,16V18H13V16H8Z"/></svg>',

        // Textos localizados
        l10n: {
            es: 'Subir Imágenes',
            en: 'Upload Images',
            fr: 'Télécharger des images'
        },

        // Vendors soportados (compatible con imgbb)
        vendors: {
            default: {
                check: function () {
                    return 1;
                },
                getEditor: function () {
                    var selectors = {
                        textarea: {
                            name: [
                                'mediainfo',
                                'bdinfo', 
                                'description',
                                'message',
                                'content'
                            ]
                        }
                    };

                    var exclusions = [];
                    for (var type in selectors) {
                        for (var attr in selectors[type]) {
                            selectors[type][attr].forEach(function(name) {
                                exclusions.push(':not([' + attr + '*="' + name + '"])');
                            });
                        }
                    }

                    return document.querySelectorAll(
                        'textarea:not([readonly])' + exclusions.join('') + 
                        ',[contenteditable="true"]'
                    );
                }
            }
        },

        // Generar GUID único
        generateGuid: function () {
            var d = new Date().getTime();
            if (typeof performance !== 'undefined' && typeof performance.now === 'function') {
                d += performance.now();
            }
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
                var r = (d + Math.random() * 16) % 16 | 0;
                d = Math.floor(d / 16);
                return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
            });
        },

        // Formatear valor de retorno para insertar en el editor
        getNewValue: function (target, response) {
            // Extraer BBCode de la respuesta
            var bbcode = '';
            
            if (response.data && response.data.bbcode_full) {
                bbcode = response.data.bbcode_full;
            } else if (response.data && response.data.url) {
                bbcode = '[img]' + response.data.url + '[/img]';
            }

            // Ajustar formato para diferentes tipos de editor
            var isContentEditable = typeof target.getAttribute('contenteditable') === 'string';
            var separator = isContentEditable ? '<br>' : '\n';
            var currentValue = target[isContentEditable ? 'innerHTML' : 'value'];
            
            var newValue = bbcode.replace(/\[img\]/g, '[img=350]').replace(/\n/g, ' ');
            
            // Agregar separadores apropiados
            if (currentValue.length > 0) {
                var trailingNewlines = currentValue.match(/\n+$/g);
                var newlineCount = trailingNewlines ? trailingNewlines[0].split('\n').length : 0;
                
                if (newlineCount <= 2) {
                    var needed = newlineCount === 0 ? 2 : 1;
                    newValue = separator.repeat(needed) + newValue;
                }
            }
            
            return newValue;
        },

        // Insertar triggers en el DOM
        insertTrigger: function () {
            var self = this;
            var vendor = this.vendors[this.settings.vendor];
            var editors;

            if (this.settings.mode === 'auto') {
                editors = this.vendors.default.getEditor();
            } else {
                // Modo manual con data-target
                var triggers = document.querySelectorAll('[' + this.ns.dataPluginTrigger + '][data-target]');
                var targets = [];
                
                for (var i = 0; i < triggers.length; i++) {
                    targets.push(triggers[i].dataset.target);
                }
                
                if (targets.length > 0) {
                    editors = document.querySelectorAll(targets.join(','));
                }
            }

            if (!editors || editors.length === 0) {
                return;
            }

            // Crear estilo CSS si no existe
            if (!document.getElementById(this.ns.pluginStyle) && this.settings.css) {
                var style = document.createElement('style');
                style.type = 'text/css';
                style.id = this.ns.pluginStyle;
                style.innerHTML = this.applyTemplate(this.settings.css);
                document.head.appendChild(style);
            }

            // Convertir NodeList a array
            if (editors.constructor !== Array) {
                editors = Array.prototype.slice.call(editors);
            }

            // Insertar botones
            var insertedCount = 0;
            editors.forEach(function(editor) {
                if (!editor.getAttribute(self.ns.dataPluginTarget)) {
                    var container = document.createElement('div');
                    container.innerHTML = self.applyTemplate(self.settings.html);
                    
                    var button = container.querySelector('[' + self.ns.dataPluginTrigger + ']');
                    self.setBoundId(button, editor);
                    
                    // Insertar después del editor
                    editor.parentNode.insertBefore(container.firstElementChild, editor.nextSibling);
                    insertedCount++;
                }
            });

            this.triggerCounter = insertedCount;
        },

        // Aplicar plantillas con variables
        applyTemplate: function (template) {
            if (!this.cacheTable) {
                var replacements = [
                    { '%iconSvg': this.iconSvg },
                    { '%text': this.settings.langString },
                    { '%cClass': this.settings.containerClass || this.ns.plugin + '-container' },
                    { '%bClass': this.settings.buttonClass || this.ns.plugin + '-button' },
                    { '%iClass': (this.settings.buttonClass || this.ns.plugin + '-button') + '-icon' },
                    { '%tClass': (this.settings.buttonClass || this.ns.plugin + '-button') + '-text' },
                    { '%x': this.ns.dataPluginTrigger },
                    { '%p': this.ns.plugin }
                ];

                // Agregar colores de paleta
                if (this.palette) {
                    for (var i = 0; i < this.palette.length; i++) {
                        replacements.push({ ['%' + (i + 1)]: this.palette[i] || '' });
                    }
                }

                this.cacheTable = replacements;
            }

            return this.strtr(template, this.cacheTable);
        },

        // Reemplazar strings con tabla de reemplazos
        strtr: function (str, replacements) {
            if (!str || typeof str !== 'string' || !replacements) return str;
            
            replacements.forEach(function(replacement) {
                for (var search in replacement) {
                    if (replacement[search] !== undefined) {
                        var regex = new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g');
                        str = str.replace(regex, replacement[search]);
                    }
                }
            });
            
            return str;
        },

        // Establecer IDs de vinculación entre botón y editor
        setBoundId: function (button, editor) {
            var id = this.generateGuid();
            button.setAttribute(this.ns.dataPluginId, id);
            editor.setAttribute(this.ns.dataPluginTarget, id);
        },

        // Abrir popup/modal de subida
        openPopup: function (id) {
            var self = this;
            
            if (!this.popups) this.popups = {};
            
            if (!this.popups[id]) {
                // Crear modal personalizado en lugar de popup
                this.createModal(id);
            } else {
                // Mostrar modal existente
                this.popups[id].modal.style.display = 'block';
            }
        },

        // Crear modal personalizado
        createModal: function (id) {
            var self = this;
            
            // Crear elementos del modal
            var modal = document.createElement('div');
            modal.className = 'unit3d-uploader-modal';
            modal.innerHTML = `
                <div class="unit3d-uploader-modal-content">
                    <div class="unit3d-uploader-modal-header">
                        <h3>📤 Subir Imágenes</h3>
                        <button class="unit3d-uploader-modal-close" type="button">&times;</button>
                    </div>
                    <div class="unit3d-uploader-modal-body">
                        <div class="unit3d-uploader-drop-zone">
                            <div class="unit3d-uploader-drop-zone-content">
                                <div class="unit3d-uploader-icon">📁</div>
                                <p>Arrastra imágenes aquí o haz clic para seleccionar</p>
                                <small>JPG, PNG, GIF, WEBP (máx. 10MB)</small>
                            </div>
                            <input type="file" class="unit3d-uploader-file-input" multiple accept="image/*" style="display: none;">
                        </div>
                        <div class="unit3d-uploader-url-section">
                            <input type="url" class="unit3d-uploader-url-input" placeholder="https://ejemplo.com/imagen.jpg">
                            <button class="unit3d-uploader-url-button" type="button">Subir desde URL</button>
                        </div>
                        <div class="unit3d-uploader-progress" style="display: none;">
                            <div class="unit3d-uploader-progress-bar">
                                <div class="unit3d-uploader-progress-fill"></div>
                            </div>
                            <div class="unit3d-uploader-progress-text">Subiendo...</div>
                        </div>
                        <div class="unit3d-uploader-results"></div>
                    </div>
                    <div class="unit3d-uploader-modal-footer">
                        <button class="unit3d-uploader-upload-button" type="button" disabled>Subir Seleccionadas</button>
                        <button class="unit3d-uploader-cancel-button" type="button">Cancelar</button>
                    </div>
                </div>
            `;

            // Estilos del modal
            var styles = `
                .unit3d-uploader-modal {
                    display: block;
                    position: fixed;
                    z-index: 10000;
                    left: 0;
                    top: 0;
                    width: 100%;
                    height: 100%;
                    background-color: rgba(0,0,0,0.5);
                    animation: fadeIn 0.3s ease;
                }
                .unit3d-uploader-modal-content {
                    position: relative;
                    background-color: #fff;
                    margin: 5% auto;
                    padding: 0;
                    border-radius: 10px;
                    width: 80%;
                    max-width: 600px;
                    box-shadow: 0 10px 30px rgba(0,0,0,0.3);
                    animation: slideIn 0.3s ease;
                }
                .unit3d-uploader-modal-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    padding: 20px;
                    background: linear-gradient(45deg, #667eea, #764ba2);
                    color: white;
                    border-radius: 10px 10px 0 0;
                }
                .unit3d-uploader-modal-header h3 {
                    margin: 0;
                    font-size: 18px;
                }
                .unit3d-uploader-modal-close {
                    background: none;
                    border: none;
                    font-size: 24px;
                    color: white;
                    cursor: pointer;
                    padding: 0;
                    width: 30px;
                    height: 30px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    border-radius: 50%;
                    transition: background 0.2s;
                }
                .unit3d-uploader-modal-close:hover {
                    background: rgba(255,255,255,0.2);
                }
                .unit3d-uploader-modal-body {
                    padding: 20px;
                }
                .unit3d-uploader-drop-zone {
                    border: 2px dashed #ddd;
                    border-radius: 8px;
                    padding: 40px;
                    text-align: center;
                    cursor: pointer;
                    transition: all 0.3s ease;
                    margin-bottom: 20px;
                }
                .unit3d-uploader-drop-zone:hover,
                .unit3d-uploader-drop-zone.dragover {
                    border-color: #667eea;
                    background-color: #f8f9ff;
                }
                .unit3d-uploader-icon {
                    font-size: 48px;
                    margin-bottom: 10px;
                }
                .unit3d-uploader-url-section {
                    display: flex;
                    gap: 10px;
                    margin-bottom: 20px;
                }
                .unit3d-uploader-url-input {
                    flex: 1;
                    padding: 10px;
                    border: 1px solid #ddd;
                    border-radius: 5px;
                }
                .unit3d-uploader-url-button,
                .unit3d-uploader-upload-button {
                    background: linear-gradient(45deg, #667eea, #764ba2);
                    color: white;
                    border: none;
                    padding: 10px 20px;
                    border-radius: 5px;
                    cursor: pointer;
                    transition: transform 0.2s;
                }
                .unit3d-uploader-url-button:hover,
                .unit3d-uploader-upload-button:hover {
                    transform: translateY(-1px);
                }
                .unit3d-uploader-upload-button:disabled {
                    background: #ccc;
                    cursor: not-allowed;
                    transform: none;
                }
                .unit3d-uploader-cancel-button {
                    background: #6c757d;
                    color: white;
                    border: none;
                    padding: 10px 20px;
                    border-radius: 5px;
                    cursor: pointer;
                    margin-left: 10px;
                }
                .unit3d-uploader-modal-footer {
                    padding: 20px;
                    text-align: right;
                    border-top: 1px solid #eee;
                }
                .unit3d-uploader-progress {
                    margin: 20px 0;
                }
                .unit3d-uploader-progress-bar {
                    width: 100%;
                    height: 8px;
                    background: #f0f0f0;
                    border-radius: 4px;
                    overflow: hidden;
                    margin-bottom: 10px;
                }
                .unit3d-uploader-progress-fill {
                    height: 100%;
                    background: linear-gradient(45deg, #667eea, #764ba2);
                    width: 0%;
                    transition: width 0.3s ease;
                }
                .unit3d-uploader-results {
                    max-height: 200px;
                    overflow-y: auto;
                }
                @keyframes fadeIn {
                    from { opacity: 0; }
                    to { opacity: 1; }
                }
                @keyframes slideIn {
                    from { transform: translateY(-50px); opacity: 0; }
                    to { transform: translateY(0); opacity: 1; }
                }
            `;

            // Agregar estilos si no existen
            if (!document.getElementById('unit3d-uploader-modal-styles')) {
                var styleSheet = document.createElement('style');
                styleSheet.id = 'unit3d-uploader-modal-styles';
                styleSheet.textContent = styles;
                document.head.appendChild(styleSheet);
            }

            // Agregar modal al DOM
            document.body.appendChild(modal);

            // Configurar eventos del modal
            this.setupModalEvents(modal, id);

            // Guardar referencia
            this.popups[id] = { modal: modal };
        },

        // Configurar eventos del modal
        setupModalEvents: function (modal, editorId) {
            var self = this;
            var dropZone = modal.querySelector('.unit3d-uploader-drop-zone');
            var fileInput = modal.querySelector('.unit3d-uploader-file-input');
            var urlInput = modal.querySelector('.unit3d-uploader-url-input');
            var urlButton = modal.querySelector('.unit3d-uploader-url-button');
            var uploadButton = modal.querySelector('.unit3d-uploader-upload-button');
            var cancelButton = modal.querySelector('.unit3d-uploader-cancel-button');
            var closeButton = modal.querySelector('.unit3d-uploader-modal-close');
            var progressDiv = modal.querySelector('.unit3d-uploader-progress');
            var progressFill = modal.querySelector('.unit3d-uploader-progress-fill');
            var progressText = modal.querySelector('.unit3d-uploader-progress-text');
            var resultsDiv = modal.querySelector('.unit3d-uploader-results');
            
            var selectedFiles = [];

            // Eventos de arrastrar y soltar
            dropZone.addEventListener('click', function () {
                fileInput.click();
            });

            dropZone.addEventListener('dragover', function (e) {
                e.preventDefault();
                dropZone.classList.add('dragover');
            });

            dropZone.addEventListener('dragleave', function (e) {
                e.preventDefault();
                dropZone.classList.remove('dragover');
            });

            dropZone.addEventListener('drop', function (e) {
                e.preventDefault();
                dropZone.classList.remove('dragover');
                var files = Array.from(e.dataTransfer.files).filter(f => f.type.startsWith('image/'));
                handleFileSelection(files);
            });

            // Evento de selección de archivos
            fileInput.addEventListener('change', function (e) {
                var files = Array.from(e.target.files);
                handleFileSelection(files);
            });

            // Manejar selección de archivos
            function handleFileSelection(files) {
                selectedFiles = files;
                uploadButton.disabled = files.length === 0;
                
                if (files.length > 0) {
                    resultsDiv.innerHTML = `
                        <div style="padding: 10px; background: #f8f9fa; border-radius: 5px; margin: 10px 0;">
                            <strong>📋 ${files.length} archivo(s) seleccionado(s):</strong><br>
                            ${files.map(f => `• ${f.name} (${formatBytes(f.size)})`).join('<br>')}
                        </div>
                    `;
                }
            }

            // Subir archivos seleccionados
            uploadButton.addEventListener('click', function () {
                if (selectedFiles.length === 0) return;
                
                uploadFiles(selectedFiles);
            });

            // Subir desde URL
            urlButton.addEventListener('click', function () {
                var url = urlInput.value.trim();
                if (!url) return;
                
                uploadFromUrl(url);
            });

            // Cerrar modal
            function closeModal() {
                modal.style.display = 'none';
                setTimeout(() => modal.remove(), 300);
                delete self.popups[editorId];
            }

            closeButton.addEventListener('click', closeModal);
            cancelButton.addEventListener('click', closeModal);
            
            modal.addEventListener('click', function (e) {
                if (e.target === modal) closeModal();
            });

            // Función para subir archivos
            function uploadFiles(files) {
                var formData = new FormData();
                files.forEach(file => formData.append('images', file));
                
                progressDiv.style.display = 'block';
                progressFill.style.width = '0%';
                progressText.textContent = 'Subiendo archivos...';
                uploadButton.disabled = true;

                fetch(self.settings.url + '/upload', {
                    method: 'POST',
                    body: formData
                })
                .then(response => {
                    progressFill.style.width = '70%';
                    return response.json();
                })
                .then(data => {
                    progressFill.style.width = '100%';
                    progressText.textContent = 'Completado';
                    
                    setTimeout(() => {
                        progressDiv.style.display = 'none';
                        handleUploadResponse(data, editorId);
                    }, 1000);
                })
                .catch(error => {
                    progressDiv.style.display = 'none';
                    resultsDiv.innerHTML = `<div style="color: red;">❌ Error: ${error.message}</div>`;
                })
                .finally(() => {
                    uploadButton.disabled = false;
                });
            }

            // Función para subir desde URL
            function uploadFromUrl(url) {
                progressDiv.style.display = 'block';
                progressFill.style.width = '50%';
                progressText.textContent = 'Descargando desde URL...';

                fetch(self.settings.url + '/upload/url', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ url: url })
                })
                .then(response => {
                    progressFill.style.width = '100%';
                    return response.json();
                })
                .then(data => {
                    progressText.textContent = 'Completado';
                    
                    setTimeout(() => {
                        progressDiv.style.display = 'none';
                        handleUploadResponse(data, editorId);
                        urlInput.value = '';
                    }, 1000);
                })
                .catch(error => {
                    progressDiv.style.display = 'none';
                    resultsDiv.innerHTML = `<div style="color: red;">❌ Error: ${error.message}</div>`;
                });
            }

            // Formatear bytes
            function formatBytes(bytes, decimals = 2) {
                if (bytes === 0) return '0 Bytes';
                const k = 1024;
                const sizes = ['Bytes', 'KB', 'MB', 'GB'];
                const i = Math.floor(Math.log(bytes) / Math.log(k));
                return parseFloat((bytes / Math.pow(k, i)).toFixed(decimals)) + ' ' + sizes[i];
            }
        },

        // Manejar respuesta de subida
        handleUploadResponse: function (response, editorId) {
            var editor = document.querySelector('[' + this.ns.dataPluginTarget + '="' + editorId + '"]');
            
            if (!editor) {
                console.error('Editor not found for ID:', editorId);
                return;
            }

            // Insertar resultado en el editor
            if (response.success && response.data) {
                var message = response.data;
                var newValue = this.getNewValue(editor, { data: message });
                
                var isContentEditable = typeof editor.getAttribute('contenteditable') === 'string';
                var prop = isContentEditable ? 'innerHTML' : 'value';
                
                editor[prop] += newValue;
                
                // Disparar eventos para notificar el cambio
                ['input', 'change', 'paste'].forEach(eventType => {
                    editor.dispatchEvent(new Event(eventType, { bubbles: true }));
                });

                // Cerrar modal
                if (this.popups[editorId]) {
                    this.popups[editorId].modal.style.display = 'none';
                    setTimeout(() => {
                        this.popups[editorId].modal.remove();
                        delete this.popups[editorId];
                    }, 300);
                }
            }
        },

        // Event binding dinámico
        liveBind: function (selector, event, callback) {
            document.addEventListener(event, function (e) {
                var targets = document.querySelectorAll(selector);
                var target = e.target;
                var found = false;
                
                while (target && !found) {
                    for (var i = 0; i < targets.length; i++) {
                        if (targets[i] === target) {
                            found = true;
                            break;
                        }
                    }
                    target = target.parentElement;
                }
                
                if (found) {
                    e.preventDefault();
                    callback.call(e, target);
                }
            }, true);
        },

        // Preparación inicial
        prepare: function () {
            var self = this;
            
            // Configurar namespace
            this.ns.dataPlugin = 'data-' + this.ns.plugin;
            this.ns.dataPluginId = this.ns.dataPlugin + '-id';
            this.ns.dataPluginTrigger = this.ns.dataPlugin + '-trigger';
            this.ns.dataPluginTarget = this.ns.dataPlugin + '-target';
            this.ns.pluginStyle = this.ns.plugin + '-style';
            this.ns.selDataPluginTrigger = '[' + this.ns.dataPluginTrigger + ']';

            // Configuración desde script tag o por defecto
            var script = document.currentScript || document.getElementById(this.ns.plugin + '-src');
            var dataset = script ? script.dataset : {};

            // Combinar configuración
            this.settings = {};
            for (var key in this.defaultSettings) {
                this.settings[key] = dataset[key] || this.defaultSettings[key];
            }

            // Configurar paleta de colores
            var paletteKey = this.settings.palette;
            this.palette = this.palettes[paletteKey] || this.palettes.default;

            // Configurar idioma
            var lang = this.settings.lang === 'auto' ? 
                (navigator.language || navigator.userLanguage).substring(0, 2) : 
                this.settings.lang;
            
            this.settings.langString = this.l10n[lang] || this.l10n.es;

            // Inicializar según configuración
            if (this.settings.init === 'onload') {
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', () => this.init());
                } else {
                    this.init();
                }
            }
        },

        // Inicialización principal
        init: function () {
            var self = this;
            
            // Insertar triggers
            this.insertTrigger();

            // Configurar event listeners
            this.liveBind(this.ns.selDataPluginTrigger, 'click', function (button) {
                var id = button.getAttribute(self.ns.dataPluginId);
                if (id) {
                    self.openPopup(id);
                }
            });

            this.initialized = true;
        }
    };

    // Auto-inicializar
    UNIT3DUploader.prepare();

    // Exponer globalmente para compatibilidad
    window.UNIT3DUploader = UNIT3DUploader;
})();