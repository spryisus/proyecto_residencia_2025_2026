import 'package:flutter/material.dart';
import 'track_shipment_screen.dart';
import 'shipment_reports_screen.dart';

class ShipmentsScreen extends StatelessWidget {
  const ShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envíos'),
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
              'Módulo de Envíos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestiona y consulta información sobre envíos:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    // Una columna en pantallas pequeñas
                    return Column(
                      children: [
                        Expanded(
                          child: _buildEnvioOptionCard(
                            context,
                            icon: Icons.local_shipping,
                            title: 'Rastrear Envío',
                            subtitle: 'Consulta el estado de tus envíos',
                            color: Colors.blue,
                            onTap: () => _navigateToTrackShipment(context),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: _buildEnvioOptionCard(
                            context,
                            icon: Icons.assessment,
                            title: 'Reportes de Envíos',
                            subtitle: 'Genera reportes y estadísticas',
                            color: Colors.green,
                            onTap: () => _navigateToShipmentReports(context),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Dos columnas centradas en pantallas medianas y grandes
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildEnvioOptionCard(
                            context,
                            icon: Icons.local_shipping,
                            title: 'Rastrear Envío',
                            subtitle: 'Consulta el estado de tus envíos',
                            color: Colors.blue,
                            onTap: () => _navigateToTrackShipment(context),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 1,
                          child: _buildEnvioOptionCard(
                            context,
                            icon: Icons.assessment,
                            title: 'Reportes de Envíos',
                            subtitle: 'Genera reportes y estadísticas',
                            color: Colors.green,
                            onTap: () => _navigateToShipmentReports(context),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvioOptionCard(
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

  void _navigateToTrackShipment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrackShipmentScreen(),
      ),
    );
  }

  void _navigateToShipmentReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ShipmentReportsScreen(),
      ),
    );
  }
}
