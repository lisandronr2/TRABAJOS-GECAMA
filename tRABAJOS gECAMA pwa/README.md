# TRABAJOS GECAMA — PWA

## Archivos incluidos
```
gecama-pwa/
├── index.html      ← App principal (abre este en el navegador)
├── manifest.json   ← Configuración PWA (nombre, iconos, shortcuts)
├── sw.js           ← Service Worker (cache offline + updates)
├── icon.svg        ← Icono de la app
└── README.md       ← Este archivo
```

## Cómo instalar como app nativa
1. Sube los 4 archivos a cualquier servidor web (Netlify, GitHub Pages, tu propio servidor, etc.)
2. Abre la URL en Chrome, Edge o Safari
3. Verás el botón "Instalar" en la barra del navegador → clícalo
4. La app se instala en tu escritorio/móvil como app nativa

## Auto-sincronización con Google Drive
- Al abrir la app, intenta descargar la última versión del Excel desde Google Drive
- Se sincroniza automáticamente cada 5 minutos
- Al volver a la pestaña/app también se sincroniza
- Si no hay conexión, usa los datos en caché (IndexedDB)
- Botón "↻ Sync" para forzar sincronización manual

## Requisitos para que el sync funcione
El archivo de Google Drive debe ser accesible. Opciones:
A) **Compartido públicamente** (Compartir → Cualquiera con el enlace puede ver)
B) **Con sesión activa de Google** en el navegador (Chrome con cuenta Google logueada)

## Hojas disponibles
- FIBRA CCTV (85 registros)
- FTP SSAA (433 registros)  
- ALIM. 3X6 (264 registros)
- RS485 (720 registros)
- BESS (111 registros)
- RESUMEN, MONTAJE CAMARAS, MONTAJE CTS, CTS FUSIONADOS
- FUSIONES SSP-SS2, MONTAJES NCUS, MONTAJE ARMARIOS CCTV
- PUENTES AEROGENERADORES
