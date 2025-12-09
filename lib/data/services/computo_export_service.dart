import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../../app/config/excel_service_config.dart';

// Importar para web (solo disponible en web)
import 'dart:html' as html if (dart.library.html) 'dart:html';

/// Servicio para exportar datos de equipos de cómputo a Excel
class ComputoExportService {
  /// Obtiene la URL del servicio según la plataforma (web/móvil)
  static String get _excelServiceUrl => ExcelServiceConfig.getServiceUrl();
  
  /// Exporta datos de equipos de cómputo a Excel
  /// 
  /// [items] Lista de equipos de cómputo con todos los campos del esquema SQL
  /// 
  /// Retorna la ruta del archivo guardado o mensaje de descarga
  static Future<String?> exportComputoToExcel(List<Map<String, dynamic>> items) async {
    try {
      if (items.isEmpty) {
        throw Exception('No hay datos para exportar');
      }

      // Preparar los datos para el endpoint según la plantilla (14 columnas, incluyendo COMPONENTES)
      // 1: ID, 2: TIPO DE EQUIPO, 3: MARCA, 4: MODELO, 5: PROCESADOR,
      // 6: NUMERO DE SERIE, 7: DISCO DURO, 8: MEMORIA, 9: SISTEMA OPERATIVO INSTALADO,
      // 10: OFFICE INSTALADO, 11: USUARIO ASIGNADO, 12: UBICACIÓN, 13: OBSERVACIONES, 14: COMPONENTES
      final payload = {
        'items': items.map((item) => {
          'inventario': item['inventario'] ?? '',
          'tipo_equipo': item['tipo_equipo'] ?? '',
          'marca': item['marca'] ?? '',
          'modelo': item['modelo'] ?? '',
          'procesador': item['procesador'] ?? '',
          'numero_serie': item['numero_serie'] ?? '',
          'disco_duro': item['disco_duro'] ?? '',
          'memoria': item['memoria'] ?? '',
          'sistema_operativo_instalado': item['sistema_operativo_instalado'] ?? item['sistema_operativo'] ?? '',
          'office_instalado': item['office_instalado'] ?? '',
          'empleado_asignado': item['empleado_asignado_nombre'] ?? item['empleado_asignado'] ?? '',
          'direccion_fisica': item['direccion_fisica'] ?? item['ubicacion_fisica'] ?? '',
          'observaciones': item['observaciones'] ?? '',
          'componentes': item['componentes'] ?? '',
        }).toList(),
      };

      // Llamar al endpoint del servicio Python
      final url = Uri.parse('$_excelServiceUrl/api/generate-computo-excel');
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
      final defaultFileName = 'Inventario_Computo_$dateStr.xlsx';

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
        dialogTitle: 'Guardar inventario de cómputo como',
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

