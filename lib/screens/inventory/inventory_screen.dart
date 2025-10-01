import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'qr_scanner_screen.dart';
import 'inventory_report_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventarios'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipos de Inventarios',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona el tipo de inventario que deseas consultar:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            // Botón de escaneo QR solo en dispositivos móviles
            if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QRScannerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 24),
                  label: const Text(
                    'Escanear Código QR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Ajustar el número de columnas según el ancho disponible
                  int crossAxisCount = 3;
                  if (constraints.maxWidth < 800) crossAxisCount = 2;
                  if (constraints.maxWidth < 600) crossAxisCount = 1;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.1,
                    children: [
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.cable,
                        title: 'Jumpers',
                        subtitle: 'Cables de conexión y jumpers',
                        color: Colors.blue,
                        onTap: () => _navigateToInventoryReport(context, 'Jumpers'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.computer,
                        title: 'Computadoras',
                        subtitle: 'Equipos de cómputo y servidores',
                        color: Colors.green,
                        onTap: () => _navigateToInventoryReport(context, 'Computadoras'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.memory,
                        title: 'Tarjetas',
                        subtitle: 'Tarjetas de red y componentes',
                        color: Colors.orange,
                        onTap: () => _navigateToInventoryReport(context, 'Tarjetas'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.router,
                        title: 'Equipos de Red',
                        subtitle: 'Routers, switches y equipos de red',
                        color: Colors.purple,
                        onTap: () => _navigateToInventoryReport(context, 'Equipos de Red'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.phone,
                        title: 'Telefonía',
                        subtitle: 'Equipos telefónicos y centrales',
                        color: Colors.teal,
                        onTap: () => _navigateToInventoryReport(context, 'Telefonía'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.power,
                        title: 'Energía',
                        subtitle: 'UPS, baterías y equipos de energía',
                        color: Colors.red,
                        onTap: () => _navigateToInventoryReport(context, 'Energía'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.storage,
                        title: 'Almacenamiento',
                        subtitle: 'Discos duros y sistemas de almacenamiento',
                        color: Colors.indigo,
                        onTap: () => _navigateToInventoryReport(context, 'Almacenamiento'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.security,
                        title: 'Seguridad',
                        subtitle: 'Equipos de seguridad y monitoreo',
                        color: Colors.brown,
                        onTap: () => _navigateToInventoryReport(context, 'Seguridad'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.build,
                        title: 'Herramientas',
                        subtitle: 'Herramientas y equipos de mantenimiento',
                        color: Colors.grey,
                        onTap: () => _navigateToInventoryReport(context, 'Herramientas'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToInventoryReport(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryReportScreen(category: category),
      ),
    );
  }
}
