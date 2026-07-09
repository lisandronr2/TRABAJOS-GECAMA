# TRABAJOS GECAMA — PWA v2.0

## Cambios en esta versión

✅ **Base de datos actualizada** → Google Sheets ID: `1guHu0lK-5aYV3GEzfy4KXlNqrGM9nSvjv3AepSFVI2s`
✅ **Sincronización en tiempo real** con Google Drive
✅ **Funcionamiento offline completo** con IndexedDB
✅ **Detección automática de hojas nuevas**
✅ **Sync en segundo plano** al recuperar cobertura móvil
✅ **Bidireccional**: cambios en Drive → App al instante

---

## Archivos incluidos

```
gecama-pwa/
├── index.html      ← App principal (toda la lógica aquí)
├── manifest.json   ← Configuración PWA
├── sw.js           ← Service Worker (cache offline + updates)
├── icon.svg        ← Icono de la app
└── README.md       ← Este archivo
```

---

## ⚠️ REQUISITO CRÍTICO — Configurar el Google Sheet como público

Para que la sincronización funcione, el archivo de Google Drive **debe ser accesible públicamente**:

1. Abrir el Google Sheet en Drive
2. Clic en **Compartir** (arriba a la derecha)
3. En "Acceso general" → seleccionar **"Cualquier persona con el enlace"**
4. Rol: **"Lector"** (solo lectura es suficiente)
5. Copiar el enlace y cerrar

> Sin este paso, la app no puede descargar los datos.

---

## Cómo instalar como app nativa

1. Subir los 4 archivos a cualquier servidor HTTPS (GitHub Pages, Netlify, Vercel, etc.)
2. Abrir la URL en Chrome, Edge o Safari en móvil
3. Verás el banner "Instalar" → tocarlo
4. La app queda instalada en el escritorio/móvil como app nativa
5. Funciona sin conexión usando los últimos datos sincronizados

---

## Cómo funciona la sincronización

### Al abrir la app
1. Carga inmediatamente los datos del caché local (IndexedDB) → sin esperas
2. En paralelo, descarga las hojas más recientes de Google Drive
3. Si hay cambios, actualiza la pantalla automáticamente

### Cada 5 minutos
- Verifica si hay cambios en el Drive y actualiza los datos en segundo plano

### Al volver al móvil (recuperar cobertura)
- Detecta el evento `online` y sincroniza de inmediato
- También sincroniza al volver a la pestaña/app después de 2+ minutos

### Al editar el Drive manualmente
- Los cambios aparecerán en la app en el siguiente ciclo de sync (máx. 5 min)
- O al pulsar el botón **↻ Sync** para forzar actualización inmediata

### Al añadir una hoja nueva al Drive
- La próxima sincronización la detecta automáticamente
- Aparece marcada con **🆕** en el selector de hojas
- Se trata igual que las hojas existentes (filtros, búsqueda, estadísticas)

---

## Cambiar el spreadsheet de origen

Solo hay que modificar una línea en `index.html`:

```javascript
const SHEET_ID = '1guHu0lK-5aYV3GEzfy4KXlNqrGM9nSvjv3AepSFVI2s';
```

Reemplazar el ID por el del nuevo spreadsheet (la parte larga de la URL entre `/d/` y `/edit`).

---

## Requisitos del formato de hojas

Cada hoja de Google Sheets debe tener:
- **Fila 1**: Encabezados de columnas
- **Filas 2+**: Datos
- No hay límite de columnas ni filas

La app detecta automáticamente los tipos de datos y calcula sumatorios para columnas numéricas.
