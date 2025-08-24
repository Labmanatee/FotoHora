import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/location_service.dart'; // RUTA CORREGIDA
import 'camera_page.dart'; // RUTA CORREGIDA

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _locationService.init();
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotohora Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMenuButton(
                context,
                icon: Icons.camera_alt,
                label: 'Tomar Foto / Video',
                onPressed: () {
                  if (widget.cameras.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se encontraron cámaras disponibles.')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraPage(cameras: widget.cameras),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                icon: Icons.article,
                label: 'Generar Reporte',
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Funcionalidad no implementada.')),
                    );
                },
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                icon: Icons.timer_outlined,
                label: 'Solicitar Salida / Descanso',
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Funcionalidad no implementada.')),
                    );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 18)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueGrey[700],
      ),
    );
  }
}
