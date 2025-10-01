import 'package:flutter/material.dart';

class TrackShipmentScreen extends StatefulWidget {
  const TrackShipmentScreen({super.key});

  @override
  State<TrackShipmentScreen> createState() => _TrackShipmentScreenState();
}

class _TrackShipmentScreenState extends State<TrackShipmentScreen> {
  final TextEditingController _trackingController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _shipmentData;

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void _searchShipment() async {
    if (_trackingController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un número de seguimiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simular búsqueda (aquí se conectaría con la API real)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSearching = false;
      _shipmentData = {
        'trackingNumber': _trackingController.text.trim(),
        'status': 'En tránsito',
        'origin': 'Centro de Distribución CDMX',
        'destination': 'Oficina Telmex Guadalajara',
        'estimatedDelivery': '2024-01-15',
        'currentLocation': 'Centro de Distribución Querétaro',
        'history': [
          {'date': '2024-01-10', 'time': '08:30', 'status': 'Recolectado', 'location': 'Centro de Distribución CDMX'},
          {'date': '2024-01-11', 'time': '14:20', 'status': 'En tránsito', 'location': 'Centro de Distribución Querétaro'},
          {'date': '2024-01-12', 'time': '09:15', 'status': 'En tránsito', 'location': 'Centro de Distribución Querétaro'},
        ],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastrear Envío'),
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
              'Consulta el Estado de tu Envío',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa el número de seguimiento para consultar el estado:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _trackingController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Seguimiento',
                      hintText: 'Ej: TLMX123456789',
                      prefixIcon: Icon(Icons.local_shipping),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchShipment(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSearching ? null : _searchShipment,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isSearching ? 'Buscando...' : 'Buscar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _shipmentData != null
                  ? _buildShipmentDetails()
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ingresa un número de seguimiento',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'para consultar el estado de tu envío',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información principal del envío
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, color: Color(0xFF003366)),
                      const SizedBox(width: 8),
                      Text(
                        'Envío #${_shipmentData!['trackingNumber']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Estado:', _shipmentData!['status'], Colors.blue),
                  _buildInfoRow('Origen:', _shipmentData!['origin'], Colors.grey[600]!),
                  _buildInfoRow('Destino:', _shipmentData!['destination'], Colors.grey[600]!),
                  _buildInfoRow('Entrega estimada:', _shipmentData!['estimatedDelivery'], Colors.green),
                  _buildInfoRow('Ubicación actual:', _shipmentData!['currentLocation'], Colors.orange),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Historial del envío
          const Text(
            'Historial de Seguimiento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          const SizedBox(height: 12),
          ...(_shipmentData!['history'] as List).map((event) => _buildHistoryItem(event)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF003366),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['status'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    event['location'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${event['date']} - ${event['time']}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
