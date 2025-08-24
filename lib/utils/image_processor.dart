import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class ImageProcessor {
  static Future<String?> addWatermark(XFile picture, Position location) async {
    try {
      final bytes = await picture.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        debugPrint("Error: No se pudo decodificar la imagen.");
        return null;
      }

      // Preparar texto de la marca de agua
      final timestamp = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
      final watermarkText = "$formattedDate\nLat: ${location.latitude.toStringAsFixed(5)}\nLng: ${location.longitude.toStringAsFixed(5)}";

      // Añadir la marca de agua
      // La fuente `arial_48` es una fuente bitmap integrada en la librería `image`.
      img.drawString(
        image,
        watermarkText,
        font: img.arial48,
        x: 20, // Margen izquierdo
        y: image.height - 180, // Margen inferior (ajustar según sea necesario)
        color: img.ColorRgb8(255, 255, 255),
      );

      final watermarkedBytes = img.encodeJpg(image, quality: 90);

      // Guardar la imagen procesada en un archivo temporal
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/watermarked_${timestamp.millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(watermarkedBytes);

      debugPrint("Marca de agua añadida exitosamente en: $filePath");
      return filePath;

    } catch (e) {
      debugPrint("Error al añadir la marca de agua: $e");
      return null;
    }
  }
}
