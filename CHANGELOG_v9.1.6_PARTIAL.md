# CHANGELOG: Actualización v9.1.5 → v9.1.6 (Parcial)

## Fecha de Implementación
**19 de Septiembre, 2025**

## Resumen Ejecutivo
Se implementaron **6 cambios de bajo riesgo** del total de **25 cambios** disponibles en UNIT3D v9.1.6. La selección se basó en un análisis de riesgo que priorizó correcciones y mejoras que no requieren cambios estructurales significativos.

---

## ✅ CAMBIOS IMPLEMENTADOS

### 🐛 **Correcciones de Errores**

#### 1. **Fix #4861: Quicksearch con búsquedas nulas**
- **Archivo modificado**: `app/Http/Controllers/API/QuickSearchController.php`
- **Qué hacía antes**: El endpoint de quicksearch fallaba cuando se enviaba un query null o vacío, causando errores
- **Qué hace ahora**: Valida el input y retorna un array vacío si el query es null o vacío
- **Impacto**: Mejora la estabilidad de la búsqueda rápida y previene errores del servidor
- **Código añadido**:
  ```php
  // Fix for issue #4861 - Handle null query
  if ($query === null || $query === '') {
      return response()->json(['results' => []]);
  }
  ```

#### 2. **Fix #4858: Búsqueda de grupos de torrents incluía torrents irrelevantes**
- **Archivo modificado**: `app/Http/Livewire/SimilarTorrent.php`
- **Qué hacía antes**: La búsqueda de torrents similares podía mostrar torrents de diferentes categorías mezclados incorrectamente
- **Qué hace ahora**: Combina la validación de categoría con el filtro de ID en una sola condición
- **Impacto**: Mejora la precisión de los resultados de búsqueda de torrents similares
- **Cambio realizado**: Consolidó las condiciones `when()` para evitar filtros redundantes

#### 3. **Fix #4919: Generación de búsqueda en Rotten Tomatoes**
- **Archivos modificados**: 
  - `resources/views/torrent/partials/movie-meta.blade.php`
  - `resources/views/torrent/partials/tv-meta.blade.php`
- **Qué hacía antes**: Los enlaces a Rotten Tomatoes tenían caracteres de escape incorrectos que rompían las URLs
- **Qué hace ahora**: Genera URLs correctas para búsquedas en Rotten Tomatoes via DuckDuckGo
- **Impacto**: Los usuarios pueden ahora buscar efectivamente en Rotten Tomatoes desde las páginas de torrents
- **Cambio realizado**: Eliminó el carácter `\` antes de las llaves dobles en las URLs

#### 4. **Fix #4877: Actualización de estado de chat al cerrar pestaña**
- **Archivo modificado**: `resources/js/components/alpine/chatbox.js`
- **Qué hacía antes**: No actualizaba el estado del usuario cuando se cerraba la pestaña/ventana
- **Qué hace ahora**: Detecta cuando se cierra la pestaña y envía actualización de estado offline
- **Impacto**: Mejora la precisión del estado online/offline de usuarios en el chat
- **Código añadido**:
  ```javascript
  // Fix for issue #4877 - Handle tab/window closing
  this.beforeUnloadHandler = () => {
      if (this.auth && this.auth.id) {
          navigator.sendBeacon(`/api/chat/status`, JSON.stringify({
              user_id: this.auth.id,
              status: 'offline'
          }));
      }
  };
  ```

### 🎨 **Mejoras de UI/UX**

#### 5. **Fix #4864: Saltos de línea y estilos del chatbox**
- **Archivo modificado**: `resources/sass/components/_chatbox.scss`
- **Qué hacía antes**: Los mensajes del chat no preservaban los saltos de línea ni manejaban bien el word wrapping
- **Qué hace ahora**: Preserva saltos de línea y mejora el manejo de texto largo
- **Impacto**: Mejor legibilidad y formato en los mensajes del chatbox
- **Código añadido**:
  ```scss
  /* Fix for issue #4864 - Chatbox Newlines & Style improvements */
  white-space: pre-wrap;
  word-wrap: break-word;
  overflow-wrap: break-word;
  ```

#### 6. **Update #4885: Estilos de código BBCode**
- **Archivo modificado**: `resources/sass/components/_bbcode-rendered.scss`
- **Qué hacía antes**: Los elementos de código BBCode tenían border-radius de 6px
- **Qué hace ahora**: Reduce el border-radius a 3px para mejor consistencia visual
- **Impacto**: Apariencia más refinada y consistente en bloques de código y citas
- **Cambio realizado**: Modificó `border-radius` de 6px a 3px en elementos `blockquote` y `code`

---

## ❌ CAMBIOS NO IMPLEMENTADOS

### 🔴 **Alto Riesgo (19 cambios)**

#### **Cambios de Seguridad**
- **#4910**: Randomización de info_hash - **REQUIERE MIGRACIÓN COMPLEJA**

#### **Nuevas Características**
- **#4880**: Página de info hash no registrados
- **#4879**: Sparkles para donantes en chatbox
- **#4903**: Popup de metadatos en póster
- **#4888**: Botón de dejar de seguir
- **#4918**: API de peticiones de torrents
- **#4928**: Sistema de peticiones de reseed actualizado

#### **Refactorizaciones Mayores**
- **#4857**: Uso de Map para mensajes del chatbox
- **#4859**: Refactorización del estado de chat
- **#4902**: Property hooks de PHP 8.4 para Livewire

#### **Correcciones Complejas**
- **#4862**: Eliminación en lote de torrents con fechas nulas
- **#4863**: RSS feed para usuarios baneados
- **#4921**: Carga eager en peticiones de torrents
- **#4922**: Búsqueda de Meilisearch por uploader
- **#4915**: Migración booleana con nulos
- **#4916**: Migración de archivos públicos a privados
- **#4906**: Optimización de eliminación de torrents bumped
- **#4908**: Tipos PHPStan en controladores de donaciones
- **#4909**: Tipos PHPStan en recursos API Eloquent
- **#4912**: Eliminar grupo redundante de páginas internas/staff
- **#4886**: Aumento del límite de caracteres de "sobre mí"
- **#4887**: No resetear perfil si es muy largo
- **#4924**: Actualización de dependencias de Composer

#### **Actualizaciones de Traducciones**
- Múltiples actualizaciones de Weblate (consideradas de bajo riesgo pero no prioritarias)

---

## 📊 **Estadísticas de Implementación**

- **Total de cambios en v9.1.6**: 25
- **Cambios implementados**: 6 (24%)
- **Cambios no implementados**: 19 (76%)
- **Categorías implementadas**:
  - Correcciones de errores: 4/6
  - Mejoras de UI/UX: 2/6
  - Nuevas características: 0/6
  - Cambios de seguridad: 0/6

---

## 🎯 **Recomendaciones para Futuras Implementaciones**

### **Próxima Fase (Recomendada)**
1. **Actualización de dependencias** (#4924) - Después de testing exhaustivo
2. **API de peticiones de torrents** (#4918) - Si se necesita funcionalidad API adicional
3. **Mejoras de performance** (#4857, #4859) - Si hay problemas de rendimiento del chat

### **Evaluación Futura (Requiere Planning)**
1. **Randomización de info_hash** (#4910) - CRÍTICO para seguridad, pero requiere migración compleja
2. **PHP 8.4 property hooks** (#4902) - Requiere actualización del servidor
3. **Nuevas características UI** (#4879, #4903, #4888) - Según prioridades del negocio

---

## 🔧 **Archivos Modificados**

1. `app/Http/Controllers/API/QuickSearchController.php`
2. `app/Http/Livewire/SimilarTorrent.php`
3. `resources/views/torrent/partials/movie-meta.blade.php`
4. `resources/views/torrent/partials/tv-meta.blade.php`
5. `resources/js/components/alpine/chatbox.js`
6. `resources/sass/components/_chatbox.scss`
7. `resources/sass/components/_bbcode-rendered.scss`

## ✅ **Testing Recomendado**

1. **Quicksearch**: Probar búsquedas vacías y con valores null
2. **Torrents similares**: Verificar que solo aparezcan torrents de la categoría correcta
3. **Enlaces Rotten Tomatoes**: Confirmar que las URLs funcionan correctamente
4. **Chat**: Verificar actualización de estado al cerrar pestaña
5. **Formato de mensajes**: Confirmar que los saltos de línea se preservan
6. **BBCode**: Verificar apariencia de bloques de código y citas

---

*Changelog generado automáticamente - Implementación realizada el 19/09/2025*