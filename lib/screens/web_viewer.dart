import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';

class WebViewer extends StatefulWidget {
  const WebViewer({super.key});

  @override
  State<WebViewer> createState() => _WebViewerState();
}

class _WebViewerState extends State<WebViewer> {
  final DatabaseReference _devicesRef = FirebaseDatabase.instance.ref('dispositivos');
  final DatabaseReference _locationsRef = FirebaseDatabase.instance.ref('ubicaciones');

  final Map<String, Marker> _markers = {};
  final Map<String, Polyline> _polylines = {};
  final Map<String, Color> _deviceColors = {};
  final Map<String, Map<dynamic, dynamic>> _deviceData = {};

  Color _getColorFromUid(String uid) {
    final hash = uid.hashCode;
    final random = Random(hash);
    return Color.fromRGBO(random.nextInt(200), random.nextInt(200), random.nextInt(200), 1);
  }

  Future<void> _fetchAndDrawRoutes({DateTimeRange? dateRange}) async {
    final devicesSnapshot = await _devicesRef.once();
    if (devicesSnapshot.snapshot.value == null) return;

    final devices = devicesSnapshot.snapshot.value as Map<dynamic, dynamic>;
    final newMarkers = <String, Marker>{};
    final newPolylines = <String, Polyline>{};
    final newDeviceData = <String, Map<dynamic, dynamic>>{};

    for (var key in devices.keys) {
      final deviceId = key.toString();
      final device = devices[key] as Map<dynamic, dynamic>;
      newDeviceData[deviceId] = device;

      // Assign color
      if (!_deviceColors.containsKey(deviceId)) {
        _deviceColors[deviceId] = _getColorFromUid(deviceId);
      }
      final color = _deviceColors[deviceId]!;

      // Fetch locations for polyline
      Query query = _locationsRef.child(deviceId).orderByKey();
      if (dateRange != null) {
        query = query.startAt(dateRange.start.millisecondsSinceEpoch.toString())
                     .endAt(dateRange.end.millisecondsSinceEpoch.toString());
      }

      final locationsSnapshot = await query.once();
      if (locationsSnapshot.snapshot.value != null) {
        final locations = locationsSnapshot.snapshot.value as Map<dynamic, dynamic>;
        final points = <LatLng>[];
        locations.forEach((_, loc) {
          points.add(LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble()));
        });

        if (points.isNotEmpty) {
          newPolylines[deviceId] = Polyline(points: points, color: color, strokeWidth: 4.0);

          // Marker for the last point
          final deviceName = device['nombre'] as String? ?? deviceId;
          newMarkers[deviceId] = Marker(
            width: 80.0, height: 80.0, point: points.last,
            child: Tooltip(message: deviceName, child: Icon(Icons.location_on, color: color, size: 40.0)),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
        _polylines.clear();
        _polylines.addAll(newPolylines);
        _deviceData.clear();
        _deviceData.addAll(newDeviceData);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAndDrawRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fotohora Tracker - Visor Web')),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: FlutterMap(
              options: MapOptions(initialCenter: LatLng(4.7110, -74.0721), initialZoom: 13.0),
              children: [
                TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
                PolylineLayer(polylines: _polylines.values.toList()),
                MarkerLayer(markers: _markers.values.toList()),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: _ControlPanel(
              deviceColors: _deviceColors,
              deviceData: _deviceData,
              onFilter: (dateRange) {
                _fetchAndDrawRoutes(dateRange: dateRange);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatefulWidget {
  final Map<String, Color> deviceColors;
  final Map<String, Map<dynamic, dynamic>> deviceData;
  final Function(DateTimeRange) onFilter;

  const _ControlPanel({required this.deviceColors, required this.deviceData, required this.onFilter});

  @override
  State<_ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<_ControlPanel> {
  final _configRef = FirebaseDatabase.instance.ref('config');
  final _usersRef = FirebaseDatabase.instance.ref('usuarios');
  final _walkingController = TextEditingController();
  final _vehicleController = TextEditingController();
  StreamSubscription? _configSubscription, _usersSubscription;
  final Map<String, Map<dynamic, dynamic>> _usersData = {};
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _listenToConfig();
    _listenToUsers();
    _selectedDateRange = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 1)), end: DateTime.now());
  }

  // ... (listenToConfig, updateConfig, listenToUsers methods are the same) ...

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    _usersSubscription?.cancel();
    _walkingController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: ListView(
        children: [
          Text('Configuración de Rastreo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          // ... (Config TextFields and Button) ...
          const Divider(height: 40),
          Text('Filtro de Recorrido', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Desde: ${formatter.format(_selectedDateRange!.start)}'),
          Text('Hasta: ${formatter.format(_selectedDateRange!.end)}'),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _selectDateRange, child: const Text('Seleccionar Fechas')),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => widget.onFilter(_selectedDateRange!), child: const Text('Aplicar Filtro')),
          const Divider(height: 40),
          Text('Dispositivos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          // ... (Device list ListView.builder) ...
        ],
      ),
    );
  }
}
