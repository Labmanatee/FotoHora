import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;
  const PreviewScreen({super.key, required this.imagePath});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _isProcessing = false;

  Future<void> _shareWithWatermark() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Get location and geocode it
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      String address = "${place.street}, ${place.locality}, ${place.country}";

      // 2. Format date and coordinates
      String dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      String coordinates = "Lat: ${position.latitude.toStringAsFixed(5)}, Lon: ${position.longitude.toStringAsFixed(5)}";

      // 3. Load the image and add watermark
      final originalImage = img.decodeImage(await File(widget.imagePath).readAsBytes());
      if (originalImage == null) throw Exception("Could not decode image");

      // Create watermark text
      String watermarkText = "$dateTime\n$coordinates\n$address";

      // Add text watermark to the image
      // Note: The 'image' package uses a different coordinate system.
      // We will draw the text at the bottom-left.
      img.drawString(
        originalImage,
        watermarkText,
        font: img.arial24,
        x: 10,
        y: originalImage.height - 80,
        color: img.ColorRgb8(255, 255, 255),
      );

      // Placeholder for the map watermark
      img.fillRect(
        originalImage,
        x1: originalImage.width - 160, y1: originalImage.height - 160,
        x2: originalImage.width - 10, y2: originalImage.height - 10,
        color: img.ColorRgba8(0, 0, 0, 128)
      );
      img.drawString(originalImage, "Mapa aqui", font: img.arial14, x: originalImage.width - 130, y: originalImage.height - 90);


      // 4. Save the watermarked image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/watermarked_image.jpg';
      await File(tempPath).writeAsBytes(img.encodeJpg(originalImage));

      // 5. Share via WhatsApp
      final xfile = XFile(tempPath);
      await Share.shareXFiles([xfile], text: 'Foto tomada con Fotohora');

    } catch (e) {
      print("Error processing and sharing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vista Previa')),
      body: Column(
        children: [
          Expanded(
            child: Image.file(File(widget.imagePath)),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Compartir en WhatsApp'),
                onPressed: _shareWithWatermark,
              ),
            ),
        ],
      ),
    );
  }
}
