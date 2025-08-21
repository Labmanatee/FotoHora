import 'package:flutter/material.dart';
import 'package:fotohora/services/location_service.dart';
import 'package:fotohora/screens/camera_screen.dart';

class MobileTrackerUI extends StatefulWidget {
  const MobileTrackerUI({super.key});

  @override
  State<MobileTrackerUI> createState() => _MobileTrackerUIState();
}

class _MobileTrackerUIState extends State<MobileTrackerUI> {
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    // Automatically start the location service when this screen is shown
    _locationService.start();
  }

  void _navigateToTakePhoto() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
  }

  void _navigateToReports() {
    // This will navigate to the placeholder reports screen.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportes'),
        content: const Text('Implementando...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotohora Tracker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar Foto con Marca de Agua'),
              onPressed: _navigateToTakePhoto,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.article),
              label: const Text('Generar Reporte'),
              onPressed: _navigateToReports,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
