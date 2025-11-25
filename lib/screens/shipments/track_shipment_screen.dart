import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/dhl_tracking_service.dart';
import '../../domain/entities/tracking_event.dart';
import '../../widgets/tracking_timeline_widget.dart';
import '../../app/theme/app_theme.dart';
import '../../app/config/dhl_proxy_config.dart';
import 'package:intl/intl.dart';

class TrackShipmentScreen extends StatefulWidget {
  const TrackShipmentScreen({super.key});

  @override
  State<TrackShipmentScreen> createState() => _TrackShipmentScreenState();
}

class _TrackShipmentScreenState extends State<TrackShipmentScreen> {
  final TextEditingController _trackingController = TextEditingController();
  late final DHLTrackingService _trackingService;
  
  @override
  void initState() {
    super.initState();
    // Inicializar servicio con la URL correcta según la plataforma y ambiente
    // Para usar producción (cloud), cambiar a: useProduction: true
    // Para usar método directo (sin proxy), cambiar a: proxyUrl: null
    _trackingService = DHLTrackingService(
      // Si el proxy falla, puedes comentar la siguiente línea y descomentar la de abajo para usar método directo
      proxyUrl: DHLProxyConfig.getProxyUrl(useProduction: true), // ✅ Usando producción
      // proxyUrl: null, // Usar método directo si el proxy no funciona
    );
  }
  bool _isSearching = false;
  ShipmentTracking? _shipmentData;
  String? _errorMessage;

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _searchShipment() async {
    final trackingNumber = _trackingController.text.trim();
    
    if (trackingNumber.isEmpty) {
      _showError('Por favor ingresa un número de seguimiento');
      return;
    }

    // Validar formato del número de tracking
    if (!_trackingService.isValidTrackingNumber(trackingNumber)) {
      _showError('El número de seguimiento no tiene un formato válido');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _shipmentData = null;
    });

    try {
      final tracking = await _trackingService.trackShipment(trackingNumber);
      
      if (!mounted) return;
      
      setState(() {
        _isSearching = false;
        _shipmentData = tracking;
      });
    } catch (e) {
      if (!mounted) return;

    setState(() {
      _isSearching = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      
      _showError(_errorMessage!);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastrear Envío DHL'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consulta el Estado de tu Envío',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa el número de seguimiento DHL para consultar el estado:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            // Layout responsive: columna en móvil, fila en desktop
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                
                if (isMobile) {
                  // Layout móvil: columna vertical
                  return Column(
                    children: [
                      TextField(
                        controller: _trackingController,
                        decoration: InputDecoration(
                          labelText: 'Número de Seguimiento DHL',
                          hintText: 'Ej: 1234567890',
                          prefixIcon: const Icon(Icons.local_shipping),
                          border: const OutlineInputBorder(),
                          suffixIcon: _trackingController.text.trim().isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _trackingController.clear();
                                    setState(() {
                                      _shipmentData = null;
                                      _errorMessage = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _searchShipment(),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          if (_trackingController.text.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _openInBrowser(_trackingController.text.trim()),
                              icon: const Icon(Icons.open_in_browser),
                              tooltip: 'Abrir en navegador',
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                } else {
                  // Layout desktop: fila horizontal
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _trackingController,
                          decoration: InputDecoration(
                            labelText: 'Número de Seguimiento DHL',
                            hintText: 'Ej: 1234567890',
                            prefixIcon: const Icon(Icons.local_shipping),
                            border: const OutlineInputBorder(),
                            suffixIcon: _trackingController.text.trim().isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _trackingController.clear();
                                      setState(() {
                                        _shipmentData = null;
                                        _errorMessage = null;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _searchShipment(),
                          onChanged: (_) => setState(() {}),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                      if (_trackingController.text.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _openInBrowser(_trackingController.text.trim()),
                          icon: const Icon(Icons.open_in_browser),
                          tooltip: 'Abrir en navegador de DHL',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isSearching
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _shipmentData != null
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
            'para consultar el estado de tu envío DHL',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Consultando información de DHL...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final trackingNumber = _trackingController.text.trim();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al consultar',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Ocurrió un error desconocido',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'DHL puede estar bloqueando peticiones automáticas.\nUsa la opción "Abrir en navegador" para verificar directamente.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                
                if (isMobile) {
                  // Botones en columna para móvil
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _searchShipment,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Intentar de nuevo'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: trackingNumber.isNotEmpty
                              ? () => _openInBrowser(trackingNumber)
                              : null,
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Abrir en navegador'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Botones en fila para desktop
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _searchShipment,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Intentar de nuevo'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: trackingNumber.isNotEmpty
                            ? () => _openInBrowser(trackingNumber)
                            : null,
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Abrir en navegador'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInBrowser(String trackingNumber) async {
    final url = Uri.parse(
      'https://www.dhl.com/mx-es/home/tracking/tracking.html?submit=1&tracking-id=$trackingNumber'
    );
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el navegador'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Widget _buildShipmentDetails() {
    final tracking = _shipmentData!;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información principal del envío
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Envío #${tracking.trackingNumber}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Estado:',
                    tracking.status,
                    _getStatusColor(tracking.status),
                  ),
                  if (tracking.origin != null)
                    _buildInfoRow(
                      'Origen:',
                      tracking.origin!,
                      Colors.grey[700]!,
                    ),
                  if (tracking.destination != null)
                    _buildInfoRow(
                      'Destino:',
                      tracking.destination!,
                      Colors.grey[700]!,
                    ),
                  if (tracking.currentLocation != null)
                    _buildInfoRow(
                      'Ubicación actual:',
                      tracking.currentLocation!,
                      AppTheme.warningOrange,
                    ),
                  if (tracking.estimatedDelivery != null)
                    _buildInfoRow(
                      'Entrega estimada:',
                      dateFormat.format(tracking.estimatedDelivery!),
                      AppTheme.successGreen,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Historial del envío con timeline
          Text(
            'Historial de Seguimiento',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TrackingTimelineWidget(
            events: tracking.events,
            currentStatus: tracking.status,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('entregado') || statusLower.contains('delivered')) {
      return AppTheme.successGreen;
    } else if (statusLower.contains('en tránsito') || statusLower.contains('in transit')) {
      return AppTheme.warningOrange;
    } else if (statusLower.contains('recolectado') || statusLower.contains('picked up')) {
      return AppTheme.infoBlue;
    } else {
      return AppTheme.primaryBlue;
    }
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
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
}
