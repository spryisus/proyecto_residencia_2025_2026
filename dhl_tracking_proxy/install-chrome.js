#!/usr/bin/env node

/**
 * Script para instalar Chrome durante el build en Render
 * Este script se ejecuta después de npm install para asegurar que Chrome esté disponible
 */

const { execSync } = require('child_process');
const path = require('path');

console.log('📦 Instalando Chrome para Puppeteer...');

try {
  // Forzar la instalación de Chrome usando @puppeteer/browsers
  // Esto asegura que Chrome esté disponible en Render
  console.log('📥 Descargando Chrome (esto puede tardar 2-3 minutos)...');
  
  execSync('npx -y @puppeteer/browsers install chrome@stable', { 
    stdio: 'inherit',
    env: process.env,
    cwd: process.cwd()
  });
  
  console.log('✅ Chrome instalado correctamente');
} catch (installError) {
  console.log('⚠️ No se pudo instalar Chrome automáticamente.');
  console.log('💡 Chrome debería descargarse automáticamente al primer uso.');
  console.log('   Error:', installError.message);
  // No fallar el build si la instalación falla
  // Chrome se descargará al primer uso si Puppeteer está configurado correctamente
}

process.exit(0);

