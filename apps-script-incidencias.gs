// ============================================================
//  GECAMA — Web App para leer/actualizar INCIDENCIAS DIARIAS
//
//  INSTALACIÓN:
//  1. Abre el Google Sheet de GECAMA.
//  2. Menú Extensiones → Apps Script.
//  3. Borra el contenido de Code.gs y pega TODO este archivo.
//  4. Guarda (icono de disquete).
//  5. Arriba a la derecha: Implementar → Nueva implementación.
//     - Tipo: Aplicación web
//     - Ejecutar como: Yo (tu cuenta)
//     - Quién tiene acceso: Cualquier usuario
//  6. Autoriza los permisos que pida Google (es tu propia hoja).
//  7. Copia la URL que termina en /exec y pásasela a Claude para
//     pegarla en INCIDENCIAS_API_URL dentro de index.html.
// ============================================================

const SHEET_NAME = 'INCIDENCIAS DIARIAS';

function doGet(e) {
  return respond_(listIncidencias_());
}

function doPost(e) {
  try {
    const body = JSON.parse(e.postData.contents);
    if (body.action === 'update') {
      updateEstado_(body.row, body.estado);
      return respond_(listIncidencias_());
    }
    return respond_({ error: 'Acción no reconocida' });
  } catch (err) {
    return respond_({ error: err.message });
  }
}

function listIncidencias_() {
  const sh = SpreadsheetApp.getActive().getSheetByName(SHEET_NAME);
  if (!sh) return { error: 'No se encontró la hoja "' + SHEET_NAME + '"' };

  const values = sh.getDataRange().getValues();
  if (values.length < 2) return { items: [] };

  const headers = values[0].map(h => String(h).trim().toUpperCase());
  const idx = {
    fecha: headers.indexOf('FECHA'),
    parcela: headers.indexOf('PARCELA'),
    ct: headers.indexOf('CT'),
    descripcion: headers.indexOf('DESCRIPCION'),
    estado: headers.indexOf('ESTADO')
  };

  const items = [];
  for (let r = 1; r < values.length; r++) {
    const row = values[r];
    if (row.every(c => c === '' || c === null)) continue;
    items.push({
      row: r + 1, // número de fila real en el Sheet (1-based)
      fecha: formatCell_(row[idx.fecha]),
      parcela: row[idx.parcela],
      ct: row[idx.ct],
      descripcion: row[idx.descripcion],
      estado: row[idx.estado]
    });
  }
  return { items };
}

function updateEstado_(row, estado) {
  const sh = SpreadsheetApp.getActive().getSheetByName(SHEET_NAME);
  if (!sh) throw new Error('No se encontró la hoja "' + SHEET_NAME + '"');

  const headers = sh.getRange(1, 1, 1, sh.getLastColumn()).getValues()[0]
    .map(h => String(h).trim().toUpperCase());
  const col = headers.indexOf('ESTADO') + 1;
  if (col < 1) throw new Error('No se encontró la columna ESTADO');
  if (row < 2 || row > sh.getLastRow()) throw new Error('Fila inválida: ' + row);

  sh.getRange(row, col).setValue(estado);
}

function formatCell_(v) {
  if (Object.prototype.toString.call(v) === '[object Date]') {
    return Utilities.formatDate(v, Session.getScriptTimeZone(), 'dd/MM/yyyy');
  }
  return v;
}

function respond_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
