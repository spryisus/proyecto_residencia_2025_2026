import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../../app/config/excel_service_config.dart';

// Importar para web (solo disponible en web)
import 'dart:html' as html if (dart.library.html) 'dart:html';

/// Servicio para exportar datos de jumpers a Excel
class JumpersExportService {
  /// Obtiene la URL del servicio según la plataforma (web/móvil)
  static String get _excelServiceUrl => ExcelServiceConfig.getServiceUrl();
  
  /// Exporta datos de jumpers a Excel
  /// 
  /// [items] Lista de jumpers con los campos: tipo, tamano, cantidad, rack, contenedor
  /// 
  /// Retorna la ruta del archivo guardado o mensaje de descarga
  static Future<String?> exportJumpersToExcel(List<Map<String, dynamic>> items) async {
    try {
      if (items.isEmpty) {
        throw Exception('No hay datos para exportar');
      }

      // Preparar los datos para el endpoint según la plantilla
      // Columnas: B=TIPO, C=TAMAÑO, D=CANTIDAD, E=RACK, F=CONTENEDOR
      final payload = {
        'items': items.map((item) => {
          'tipo': item['tipo'] ?? item['categoryName'] ?? '',
          'tamano': item['tamano'] ?? item['size'] ?? '',
          'cantidad': item['cantidad'] ?? item['quantity'] ?? 0,
          'rack': item['rack'] ?? '',
          'contenedor': item['contenedor'] ?? item['container'] ?? '',
        }).toList(),
      };

      // Llamar al endpoint del servicio Python
      final url = Uri.parse('$_excelServiceUrl/api/generate-jumpers-excel');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al generar Excel: ${response.statusCode} - ${response.body}');
      }

      // Generar nombre por defecto con fecha
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final defaultFileName = 'Inventario_Jumpers_$dateStr.xlsx';

      // Para web, descargar directamente
      if (kIsWeb) {
        final blob = html.Blob([response.bodyBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', defaultFileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return 'Descargado: $defaultFileName';
      }

      // Para móvil/desktop, usar FilePicker
      String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar inventario de jumpers como',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (filePath == null) {
        return null; // Usuario canceló
      }

      // Asegurar que el archivo tenga la extensión .xlsx
      if (!filePath.endsWith('.xlsx')) {
        filePath = '$filePath.xlsx';
      }

      // Guardar el archivo
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath;
    } catch (e) {
      rethrow;
    }
  }
}

