const express = require('express');
const { execSync } = require('child_process');
const app = express();

app.use(express.json());

app.post('/webhook', (req, res) => {
  console.log('Webhook recibido de GitHub');
  
  try {
    execSync('git pull origin main', { cwd: process.cwd(), stdio: 'inherit' });
    console.log('✓ Git pull ejecutado exitosamente');
    res.json({ success: true, message: 'Git pull ejecutado' });
  } catch (error) {
    console.error('✗ Error en git pull:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.listen(3000, () => {
  console.log('Servidor webhook escuchando en puerto 3000');
});
