const express = require('express');
const cors = require('cors');
const puppeteer = require('puppeteer');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Habilitar CORS para que Flutter pueda hacer peticiones
app.use(cors());
app.use(express.json());

// Variable global para rastrear si Chrome ya se está descargando
let chromeDownloading = false;
let chromeDownloadPromise = null;

// Función para asegurar que Chrome esté disponible
async function ensureChrome() {
  // Si ya está descargando, esperar a que termine
  if (chromeDownloading && chromeDownloadPromise) {
    return await chromeDownloadPromise;
  }
  
  // Si ya está disponible, retornar inmediatamente
  try {
    const fs = require('fs');
    const chromePath = puppeteer.executablePath();
    if (fs.existsSync(chromePath)) {
      return true;
    }
  } catch (error) {
    // Chrome no está disponible
  }
  
  // Marcar que estamos descargando
  chromeDownloading = true;
  
  // Crear promesa para descargar Chrome
  chromeDownloadPromise = (async () => {
    try {
      console.log('⚠️ Chrome no está disponible. Descargando Chrome...');
      console.log('⏱️  Esto puede tardar 2-3 minutos la primera vez...');
      
      const { execSync } = require('child_process');
      execSync('npx -y @puppeteer/browsers install chrome@stable', {
        stdio: 'inherit',
        timeout: 180000, // 3 minutos
        env: process.env
      });
      
      console.log('✅ Chrome descargado correctamente');
      chromeDownloading = false;
      return true;
    } catch (downloadError) {
      console.log('⚠️ No se pudo descargar Chrome automáticamente.');
      console.log('💡 Se intentará usar Chrome del sistema si está disponible.');
      chromeDownloading = false;
      return false;
    }
  })();
  
  return await chromeDownloadPromise;
}

/**
 * Ruta raíz - Información del servicio
 * GET /
 */
app.get('/', (req, res) => {
  res.json({
    service: 'DHL Tracking Proxy',
    status: 'running',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      track: '/api/track/:trackingNumber',
      example: '/api/track/6376423056'
    },
    documentation: 'Este servicio permite consultar el estado de envíos DHL usando web scraping.'
  });
});

/**
 * Endpoint para consultar tracking de DHL
 * GET /api/track/:trackingNumber
 */
app.get('/api/track/:trackingNumber', async (req, res) => {
  const { trackingNumber } = req.params;
  
  if (!trackingNumber || trackingNumber.trim().length < 8) {
    return res.status(400).json({
      success: false,
      error: 'Número de tracking inválido',
    });
  }

  let browser = null;
  
  try {
    console.log(`🔍 Consultando tracking: ${trackingNumber}`);
    
    // Asegurar que Chrome esté disponible (esta función es idempotente)
    await ensureChrome();
    
    // Verificar si Chrome está disponible
    try {
      const fs = require('fs');
      const chromePath = puppeteer.executablePath();
      if (fs.existsSync(chromePath)) {
        console.log(`📍 Chrome disponible en: ${chromePath}`);
      }
    } catch (error) {
      console.log('⚠️ Chrome aún no está disponible, Puppeteer intentará encontrarlo...');
    }
    
    // Configurar opciones de lanzamiento para Render
    const launchOptions = {
      headless: 'new', // Usar el nuevo modo headless (más estable)
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--disable-gpu',
        '--disable-software-rasterizer',
        '--disable-web-security',
        '--disable-features=IsolateOrigins,site-per-process',
        '--single-process', // Para entornos con poca memoria como Render
      ],
    };
    
    console.log('🚀 Iniciando Puppeteer...');
    browser = await puppeteer.launch(launchOptions);
    console.log('✅ Puppeteer iniciado correctamente');

    const page = await browser.newPage();
    
    // Configurar User-Agent realista
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Visitar página de tracking de DHL
    const trackingUrl = `https://www.dhl.com/mx-es/home/tracking/tracking.html?submit=1&tracking-id=${trackingNumber}`;
    
    console.log(`📡 Navegando a: ${trackingUrl}`);
    
    // Ir a la página con timeout
    await page.goto(trackingUrl, {
      waitUntil: 'networkidle2', // Esperar a que la red esté inactiva
      timeout: 30000,
    });

    // Esperar más tiempo para que carguen los scripts dinámicos de DHL
    await page.waitForTimeout(5000);
    
    // Intentar hacer scroll para activar lazy loading y cargar contenido dinámico
    await page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight);
    });
    await page.waitForTimeout(2000);
    
    // Scroll hacia arriba
    await page.evaluate(() => {
      window.scrollTo(0, 0);
    });
    await page.waitForTimeout(1000);
    
    // Scroll hacia abajo de nuevo lentamente
    await page.evaluate(() => {
      const scrollHeight = document.body.scrollHeight;
      const viewportHeight = window.innerHeight;
      for (let i = 0; i < scrollHeight; i += viewportHeight / 2) {
        window.scrollTo(0, i);
      }
      window.scrollTo(0, scrollHeight);
    });
    await page.waitForTimeout(2000);
    
    // Esperar a que aparezcan elementos específicos de tracking (si existen)
    try {
      // Buscar varios selectores posibles
      await Promise.race([
        page.waitForSelector('[class*="tracking"]', { timeout: 5000 }),
        page.waitForSelector('[class*="shipment"]', { timeout: 5000 }),
        page.waitForSelector('[id*="tracking"]', { timeout: 5000 }),
        page.waitForSelector('[class*="timeline"]', { timeout: 5000 }),
        page.waitForSelector('[class*="history"]', { timeout: 5000 }),
        page.waitForSelector('table', { timeout: 5000 }),
      ]).catch(() => {
        console.log('No se encontraron selectores específicos, continuando...');
      });
    } catch (e) {
      // Si no aparecen, continuamos de todas formas
      console.log('No se encontraron selectores específicos, continuando...');
    }

    // Extraer información de la página
    const trackingData = await page.evaluate(() => {
      const data = {
        trackingNumber: '',
        status: 'No encontrado',
        events: [],
        origin: null,
        destination: null,
        currentLocation: null,
        estimatedDelivery: null,
      };

      try {
        // Buscar el contenedor principal de tracking
        // DHL suele usar estos selectores
        const trackingContainer = document.querySelector('[class*="tracking"], [class*="shipment"], [id*="tracking"], [id*="shipment"]') ||
                                 document.querySelector('main, [role="main"]') ||
                                 document.body;

        // Buscar estado en elementos específicos de tracking
        const statusSelectors = [
          '[class*="status"]',
          '[class*="state"]',
          '[data-status]',
          'h1, h2, h3',
          '.shipment-status',
          '.tracking-status',
        ];

        let statusFound = false;
        for (const selector of statusSelectors) {
          const elements = trackingContainer.querySelectorAll(selector);
          for (const elem of elements) {
            const text = elem.textContent.trim().toLowerCase();
            // Filtrar elementos que son claramente del menú
            if (text.includes('menú') || text.includes('menu') || 
                text.includes('servicio') || text.includes('encontrar') ||
                text.length < 5 || text.length > 100) {
              continue;
            }
            
            if (text.includes('entregado') || text.includes('delivered') || text.includes('delivery completed')) {
              data.status = 'Entregado';
              statusFound = true;
              break;
            } else if (text.includes('en tránsito') || text.includes('in transit') || text.includes('transit')) {
              data.status = 'En tránsito';
              statusFound = true;
            } else if (text.includes('recolectado') || text.includes('picked up') || text.includes('collected')) {
              data.status = 'Recolectado';
              statusFound = true;
            } else if (text.includes('en camino') || text.includes('on the way')) {
              data.status = 'En tránsito';
              statusFound = true;
            }
          }
          if (statusFound) break;
        }

        // Buscar eventos de tracking en elementos específicos
        // DHL suele usar listas ordenadas o divs con clases específicas
        const eventSelectors = [
          // Tablas de tracking (muy común en DHL)
          'table tr',
          'table tbody tr',
          '[class*="tracking"] table tr',
          '[class*="shipment"] table tr',
          // Listas
          '[class*="timeline"] li',
          '[class*="tracking-event"]',
          '[class*="shipment-event"]',
          '[class*="history"] li',
          '[class*="event"]',
          '[class*="status-item"]',
          '[class*="tracking-step"]',
          'ol[class*="tracking"] li',
          'ul[class*="tracking"] li',
          'div[class*="tracking"] > div',
          // Divs con información de tracking
          '[class*="tracking"] > div',
          '[class*="shipment"] > div',
          // Elementos con data attributes
          '[data-tracking-event]',
          '[data-status]',
          // Cualquier elemento que contenga fechas y estados
          'div:has-text("entregado"), div:has-text("delivered")',
          'div:has-text("tránsito"), div:has-text("transit")',
        ];

        const seenEvents = new Set();
        const excludedTexts = ['menú', 'menu', 'servicio al cliente', 'encontrar', 'obtener', 'enviar ahora', 'solicitar', 'explorar', 'seleccione', 'cambiar', 'cookie', 'privacidad', 'términos'];
        
        for (const selector of eventSelectors) {
          try {
            const elements = trackingContainer.querySelectorAll(selector);
            for (const elem of elements) {
              const text = elem.textContent.trim();
              
              // Filtrar eventos válidos más estrictamente
              const textLower = text.toLowerCase();
              const isExcluded = excludedTexts.some(excluded => textLower.includes(excluded));
              
              // Un evento válido debe tener:
              // - Longitud razonable
              // - Contener palabras clave de tracking O tener fecha/hora
              // - No ser del menú
              const hasTrackingKeywords = textLower.includes('entregado') || 
                                         textLower.includes('delivered') ||
                                         textLower.includes('tránsito') ||
                                         textLower.includes('transit') ||
                                         textLower.includes('recolectado') ||
                                         textLower.includes('picked') ||
                                         textLower.includes('enviado') ||
                                         textLower.includes('shipped') ||
                                         textLower.includes('recibido') ||
                                         textLower.includes('received') ||
                                         textLower.includes('procesado') ||
                                         textLower.includes('processed') ||
                                         textLower.includes('en camino') ||
                                         textLower.includes('on the way') ||
                                         textLower.includes('salida') ||
                                         textLower.includes('departed') ||
                                         textLower.includes('llegada') ||
                                         textLower.includes('arrived') ||
                                         textLower.match(/\d{1,2}[\/\-]\d{1,2}/) || // Tiene fecha
                                         textLower.match(/\d{1,2}:\d{2}/); // Tiene hora
              
              // Para tablas, verificar que tenga al menos 2 celdas con contenido
              const isTableRow = elem.tagName === 'TR';
              let isValidTableRow = false;
              if (isTableRow) {
                const cells = elem.querySelectorAll('td, th');
                const cellTexts = Array.from(cells).map(cell => cell.textContent.trim()).filter(t => t.length > 0);
                isValidTableRow = cellTexts.length >= 2 && cellTexts.some(cellText => {
                  const cellLower = cellText.toLowerCase();
                  return hasTrackingKeywords || cellLower.match(/\d{1,2}[\/\-]\d{1,2}/) || cellLower.match(/\d{1,2}:\d{2}/);
                });
              }
            
            if (text && text.length > 10 && text.length < 400 && 
                !isExcluded &&
                !seenEvents.has(text) &&
                (hasTrackingKeywords || isValidTableRow)) {
              seenEvents.add(text);
              
              // Intentar extraer fecha/hora del texto
              // Formato: DD/MM/YYYY o DD-MM-YYYY
              const dateMatch = text.match(/(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/);
              // Formato: HH:MM
              const timeMatch = text.match(/(\d{1,2}:\d{2}(?:\s*[AP]M)?)/i);
              
              // Intentar extraer ubicación (ciudad, estado, país)
              const locationMatch = text.match(/([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)*(?:\s+(?:CDMX|México|Mexico|MX))?)/);
              
              let timestamp = new Date().toISOString();
              if (dateMatch) {
                try {
                  let dateStr = dateMatch[1];
                  // Convertir formato DD/MM/YYYY o DD-MM-YYYY a ISO
                  const parts = dateStr.split(/[\/\-]/);
                  if (parts.length === 3) {
                    const day = parseInt(parts[0]);
                    const month = parseInt(parts[1]) - 1; // Mes es 0-indexed
                    const year = parts[2].length === 2 ? 2000 + parseInt(parts[2]) : parseInt(parts[2]);
                    
                    let hour = 0, minute = 0;
                    if (timeMatch) {
                      const timeParts = timeMatch[1].match(/(\d{1,2}):(\d{2})/);
                      if (timeParts) {
                        hour = parseInt(timeParts[1]);
                        minute = parseInt(timeParts[2]);
                        // Manejar AM/PM si existe
                        if (timeMatch[1].toUpperCase().includes('PM') && hour < 12) hour += 12;
                        if (timeMatch[1].toUpperCase().includes('AM') && hour === 12) hour = 0;
                      }
                    }
                    
                    timestamp = new Date(year, month, day, hour, minute).toISOString();
                  }
                } catch (e) {
                  // Usar timestamp actual si falla
                  console.error('Error parsing date:', e);
                }
              }
              
              let location = null;
              if (locationMatch) {
                location = locationMatch[1].trim();
              }
              
              // Limpiar descripción (remover fechas y horas para que quede más limpio)
              let description = text;
              if (dateMatch) {
                description = description.replace(dateMatch[0], '').trim();
              }
              if (timeMatch) {
                description = description.replace(timeMatch[0], '').trim();
              }
              description = description.replace(/^\s*[,\-–]\s*/, '').trim();
              
              // Si la descripción quedó muy corta, usar el texto original
              if (description.length < 5) {
                description = text;
              }
              
              data.events.push({
                description: description || text,
                timestamp: timestamp,
                location: location,
                status: data.status,
              });
            }
            }
          } catch (e) {
            // Si un selector falla, continuar con el siguiente
            console.log(`Error con selector ${selector}:`, e.message);
          }
        }
        
        // Ordenar eventos por fecha (más reciente primero)
        data.events.sort((a, b) => {
          const dateA = new Date(a.timestamp);
          const dateB = new Date(b.timestamp);
          return dateB - dateA; // Orden descendente (más reciente primero)
        });

        // Buscar ubicaciones en elementos específicos
        const locationSelectors = [
          '[class*="location"]',
          '[class*="origin"]',
          '[class*="destination"]',
          '[class*="from"]',
          '[class*="to"]',
        ];

        for (const selector of locationSelectors) {
          const elements = trackingContainer.querySelectorAll(selector);
          for (const elem of elements) {
            const text = elem.textContent.trim();
            if (text && text.length > 3 && text.length < 100) {
              const lowerText = text.toLowerCase();
              if ((lowerText.includes('origen') || lowerText.includes('origin') || lowerText.includes('from')) && !data.origin) {
                data.origin = text.replace(/origen|origin|from/gi, '').trim();
              } else if ((lowerText.includes('destino') || lowerText.includes('destination') || lowerText.includes('to')) && !data.destination) {
                data.destination = text.replace(/destino|destination|to/gi, '').trim();
              }
            }
          }
        }

        // Si no encontramos eventos pero sí encontramos el estado, crear un evento básico
        if (data.events.length === 0 && data.status !== 'No encontrado') {
          data.events.push({
            description: `Estado: ${data.status}`,
            timestamp: new Date().toISOString(),
            location: null,
            status: data.status,
          });
        }

      } catch (error) {
        console.error('Error al extraer datos:', error);
      }

      return data;
    });

    // Si no encontramos eventos, hacer un scraping más agresivo
    if (trackingData.events.length === 0) {
      console.log('⚠️  No se encontraron eventos, intentando scraping más agresivo...');
      
      // Intentar extraer de cualquier tabla o lista visible
      const aggressiveData = await page.evaluate(() => {
        const events = [];
        
        // Buscar en todas las tablas
        const tables = document.querySelectorAll('table');
        tables.forEach((table, tableIndex) => {
          const rows = table.querySelectorAll('tr');
          rows.forEach((row, rowIndex) => {
            const cells = Array.from(row.querySelectorAll('td, th'));
            if (cells.length >= 2) {
              const cellTexts = cells.map(cell => cell.textContent.trim()).filter(t => t.length > 0);
              const combinedText = cellTexts.join(' | ');
              
              // Verificar si parece un evento de tracking
              const textLower = combinedText.toLowerCase();
              if ((textLower.includes('entregado') || 
                   textLower.includes('delivered') ||
                   textLower.includes('tránsito') ||
                   textLower.includes('transit') ||
                   textLower.includes('recolectado') ||
                   textLower.includes('picked') ||
                   textLower.match(/\d{1,2}[\/\-]\d{1,2}/) ||
                   textLower.match(/\d{1,2}:\d{2}/)) &&
                  combinedText.length > 15 && combinedText.length < 500) {
                
                // Extraer fecha y hora
                const dateMatch = combinedText.match(/(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/);
                const timeMatch = combinedText.match(/(\d{1,2}:\d{2}(?:\s*[AP]M)?)/i);
                
                let timestamp = new Date().toISOString();
                if (dateMatch) {
                  try {
                    const parts = dateMatch[1].split(/[\/\-]/);
                    if (parts.length === 3) {
                      const day = parseInt(parts[0]);
                      const month = parseInt(parts[1]) - 1;
                      const year = parts[2].length === 2 ? 2000 + parseInt(parts[2]) : parseInt(parts[2]);
                      let hour = 0, minute = 0;
                      if (timeMatch) {
                        const timeParts = timeMatch[1].match(/(\d{1,2}):(\d{2})/);
                        if (timeParts) {
                          hour = parseInt(timeParts[1]);
                          minute = parseInt(timeParts[2]);
                          if (timeMatch[1].toUpperCase().includes('PM') && hour < 12) hour += 12;
                          if (timeMatch[1].toUpperCase().includes('AM') && hour === 12) hour = 0;
                        }
                      }
                      timestamp = new Date(year, month, day, hour, minute).toISOString();
                    }
                  } catch (e) {
                    // Usar timestamp actual
                  }
                }
                
                events.push({
                  description: combinedText,
                  timestamp: timestamp,
                  location: cellTexts.length > 2 ? cellTexts[2] : null,
                  status: textLower.includes('entregado') || textLower.includes('delivered') ? 'Entregado' : 
                         textLower.includes('tránsito') || textLower.includes('transit') ? 'En tránsito' : 'Desconocido',
                });
              }
            }
          });
        });
        
        // Buscar en listas ordenadas y desordenadas
        const lists = document.querySelectorAll('ol, ul');
        lists.forEach((list) => {
          const items = list.querySelectorAll('li');
          items.forEach((item) => {
            const text = item.textContent.trim();
            const textLower = text.toLowerCase();
            if (text.length > 15 && text.length < 400 &&
                (textLower.includes('entregado') || 
                 textLower.includes('delivered') ||
                 textLower.includes('tránsito') ||
                 textLower.includes('transit') ||
                 textLower.includes('recolectado') ||
                 textLower.includes('picked') ||
                 textLower.match(/\d{1,2}[\/\-]\d{1,2}/) ||
                 textLower.match(/\d{1,2}:\d{2}/))) {
              
              const dateMatch = text.match(/(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/);
              const timeMatch = text.match(/(\d{1,2}:\d{2}(?:\s*[AP]M)?)/i);
              
              let timestamp = new Date().toISOString();
              if (dateMatch) {
                try {
                  const parts = dateMatch[1].split(/[\/\-]/);
                  if (parts.length === 3) {
                    const day = parseInt(parts[0]);
                    const month = parseInt(parts[1]) - 1;
                    const year = parts[2].length === 2 ? 2000 + parseInt(parts[2]) : parseInt(parts[2]);
                    let hour = 0, minute = 0;
                    if (timeMatch) {
                      const timeParts = timeMatch[1].match(/(\d{1,2}):(\d{2})/);
                      if (timeParts) {
                        hour = parseInt(timeParts[1]);
                        minute = parseInt(timeParts[2]);
                        if (timeMatch[1].toUpperCase().includes('PM') && hour < 12) hour += 12;
                        if (timeMatch[1].toUpperCase().includes('AM') && hour === 12) hour = 0;
                      }
                    }
                    timestamp = new Date(year, month, day, hour, minute).toISOString();
                  }
                } catch (e) {
                  // Usar timestamp actual
                }
              }
              
              events.push({
                description: text,
                timestamp: timestamp,
                location: null,
                status: textLower.includes('entregado') || textLower.includes('delivered') ? 'Entregado' : 
                       textLower.includes('tránsito') || textLower.includes('transit') ? 'En tránsito' : 'Desconocido',
              });
            }
          });
        });
        
        return events;
      });
      
      if (aggressiveData && aggressiveData.length > 0) {
        trackingData.events = aggressiveData;
        console.log(`✅ Encontrados ${aggressiveData.length} eventos con scraping agresivo`);
      }
    }
    
    // Si aún no hay eventos pero sí hay estado, crear eventos básicos basados en el estado
    if (trackingData.events.length === 0 && trackingData.status !== 'No encontrado') {
      console.log('⚠️  Creando eventos básicos basados en el estado...');
      trackingData.events.push({
        description: `Estado actual: ${trackingData.status}`,
        timestamp: new Date().toISOString(),
        location: null,
        status: trackingData.status,
      });
    }
    
    trackingData.trackingNumber = trackingNumber;

    console.log(`✅ Tracking encontrado: ${trackingData.status}`);

    // Cerrar navegador
    await browser.close();

    res.json({
      success: true,
      data: trackingData,
    });

  } catch (error) {
    // Log del error completo para debugging
    console.error('❌ Error al consultar tracking:', error);
    console.error('❌ Error message:', error.message);
    console.error('❌ Error stack:', error.stack);
    
    // Cerrar browser si está abierto
    if (browser) {
      try {
        await browser.close();
      } catch (closeError) {
        console.error('❌ Error al cerrar browser:', closeError);
      }
    }
    
    // Enviar respuesta de error con detalles
    res.status(500).json({
      success: false,
      error: error.message || 'Error desconocido',
      message: 'Error al consultar DHL. Por favor intenta nuevamente.',
      details: process.env.NODE_ENV === 'production' ? undefined : error.stack,
    });
  }
});

/**
 * Endpoint de salud
 */
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'DHL Tracking Proxy' });
});

// Iniciar verificación de Chrome en background al iniciar el servidor
ensureChrome().catch(err => {
  console.log('⚠️ Error al verificar Chrome:', err.message);
});

// Iniciar servidor en todas las interfaces (0.0.0.0) para que sea accesible desde la red local
app.listen(PORT, '0.0.0.0', () => {
  const os = require('os');
  const networkInterfaces = os.networkInterfaces();
  let localIp = 'localhost';
  
  // Buscar IP local (IPv4) en interfaces de red
  for (const name of Object.keys(networkInterfaces)) {
    for (const iface of networkInterfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        localIp = iface.address;
        break;
      }
    }
    if (localIp !== 'localhost') break;
  }
  
  console.log(`🚀 Servidor DHL Tracking Proxy corriendo en puerto ${PORT}`);
  console.log(`📡 Endpoint local: http://localhost:${PORT}/api/track/:trackingNumber`);
  console.log(`📡 Endpoint red local: http://${localIp}:${PORT}/api/track/:trackingNumber`);
  console.log(`🌐 Accesible desde dispositivos en la misma red: http://${localIp}:${PORT}`);
});

