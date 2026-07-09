// Vercel serverless proxy — descarga el xlsx de Google Sheets sin CORS
const FILE_ID = '1OeKpZDLK3sc1ZLdPUiHL4njYW3NPftW2';
const EXPORT_URL = `https://docs.google.com/spreadsheets/d/${FILE_ID}/export?format=xlsx`;

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');

  try {
    const gResp = await fetch(EXPORT_URL, {
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; GECAMA-Sync/1.0)' },
      redirect: 'follow'
    });

    if (!gResp.ok) {
      return res.status(502).json({ error: `Google devolvió HTTP ${gResp.status}` });
    }

    const buf = await gResp.arrayBuffer();
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.send(Buffer.from(buf));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
