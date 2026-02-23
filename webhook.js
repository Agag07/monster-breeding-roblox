// webhook_improved.js - Auto git pull + Rojo restart
const express = require('express');
const { exec } = require('child_process');
const path = require('path');

const app = express();
const PORT = 3000;

// Middleware
app.use(express.json());

// Store the Rojo process
let rojoProcess = null;

// Function to execute shell commands
function executeCommand(command, cwd = null) {
  return new Promise((resolve, reject) => {
    const options = cwd ? { cwd } : {};
    exec(command, options, (error, stdout, stderr) => {
      if (error) {
        reject({ error: error.message, stderr });
      } else {
        resolve(stdout);
      }
    });
  });
}

// Function to restart Rojo
async function restartRojo() {
  try {
    console.log('🔄 Reiniciando Rojo...');
    
    // Kill existing Rojo process if running
    if (rojoProcess) {
      rojoProcess.kill();
      console.log('✓ Proceso anterior de Rojo terminado');
    }
    
    // Wait a moment
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Start Rojo again
    const { spawn } = require('child_process');
    rojoProcess = spawn('rojo', ['serve'], {
      cwd: 'C:\\Users\\aquil\\Desktop\\Game\\scripts',
      stdio: 'inherit',
      shell: true
    });
    
    console.log('✅ Rojo reiniciado correctamente');
    return true;
  } catch (error) {
    console.error('❌ Error al reiniciar Rojo:', error);
    return false;
  }
}

// Webhook endpoint
app.post('/webhook', async (req, res) => {
  const { ref, head_commit } = req.body;
  
  console.log('\n========================================');
  console.log('🔔 WEBHOOK RECIBIDO DE GITHUB');
  console.log('========================================');
  console.log(`📦 Rama: ${ref}`);
  console.log(`💾 Commit: ${head_commit?.message || 'N/A'}`);
  console.log('----------------------------------------');
  
  // Only process main branch
  if (ref !== 'refs/heads/main') {
    console.log('⏭️  Ignorando rama no principal');
    res.status(200).json({ status: 'ignored', message: 'Solo se procesa rama main' });
    return;
  }
  
  try {
    // Step 1: Git Pull
    console.log('📥 Ejecutando git pull...');
    const pullOutput = await executeCommand('git pull', 'C:\\Users\\aquil\\Desktop\\Game\\scripts');
    console.log('✅ Git pull completado');
    console.log(pullOutput);
    
    // Step 2: Restart Rojo
    console.log('\n🔄 Reiniciando Rojo para sincronizar cambios...');
    await restartRojo();
    
    // Response
    console.log('\n========================================');
    console.log('✅ WEBHOOK PROCESADO EXITOSAMENTE');
    console.log('========================================\n');
    
    res.status(200).json({
      status: 'success',
      message: 'Git pull completado y Rojo reiniciado',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('\n❌ ERROR AL PROCESAR WEBHOOK');
    console.error('Error:', error);
    console.log('========================================\n');
    
    res.status(500).json({
      status: 'error',
      message: error.error || 'Error desconocido',
      details: error.stderr || 'Sin detalles'
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'Webhook servidor activo',
    port: PORT,
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, () => {
  console.log('\n========================================');
  console.log('🚀 WEBHOOK SERVER INICIADO');
  console.log('========================================');
  console.log(`✅ Escuchando en puerto ${PORT}`);
  console.log(`📍 URL: http://localhost:${PORT}`);
  console.log(`🔗 Webhook: POST http://localhost:${PORT}/webhook`);
  console.log(`❤️  Health: GET http://localhost:${PORT}/health`);
  console.log('========================================\n');
  console.log('⏳ Esperando webhooks de GitHub...\n');
});

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n\n⛔ Cerrando servidor...');
  if (rojoProcess) {
    rojoProcess.kill();
  }
  process.exit(0);
});
