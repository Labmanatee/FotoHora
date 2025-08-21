import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';

class LocationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  User? _user;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription? _configSubscription;
  StreamSubscription? _connectivitySubscription;

  bool _isOnline = true;
  bool _isProcessingQueue = false;

  // Default config values
  int _walkingInterval = 10;
  int _vehicleInterval = 3;
  final double _vehicleSpeedThreshold = 5.5;
  final double _stationarySpeedThreshold = 0.5;
  final int _distanceFilter = 3;

  LocationSettings? _currentLocationSettings;

  Future<void> start() {
    if (kIsWeb) return Future.value();
    print("Iniciando servicio de ubicación...");
    return _initialize();
  }

  Future<void> _initialize() async {
    await _signIn();
    if (_user != null) {
      await _requestPermissions();
      _listenToConnectivity();
      _listenToConfig(); // This will trigger the first location update
    } else {
      print("Fallo el inicio de sesión.");
    }
  }

  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOnlineNow = results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi);
      if (_isOnline != isOnlineNow) {
        _isOnline = isOnlineNow;
        print("Estado de la conexión: ${_isOnline ? 'Online' : 'Offline'}");
        if (_isOnline) {
          _processQueue();
        }
      }
    });
  }

  // ... (signIn and requestPermissions methods remain the same) ...

  void _listenToConfig() {
    // ... (logic is the same, but now it calls _restartLocationUpdates) ...
  }

  void _restartLocationUpdates(Position? lastPosition) {
    // ... (logic is the same) ...
  }

  void _handlePositionUpdate(Position position) {
    if (position.speed < _stationarySpeedThreshold) {
      return;
    }
    _queueOrSendLocation(position);
    _restartLocationUpdates(position);
  }

  Future<void> _queueOrSendLocation(Position location) async {
    final locationData = {
      'lat': location.latitude,
      'lng': location.longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'speed_mps': location.speed,
    };

    if (_isOnline) {
      print("Enviando ubicación a Firebase...");
      await _sendToFirebase(locationData);
      await _processQueue(); // Try to send any stored locations
    } else {
      print("Guardando ubicación en la cola offline...");
      await _writeToQueue(locationData);
    }
  }

  Future<File> _getQueueFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/offline_queue.json');
  }

  Future<void> _writeToQueue(Map<String, dynamic> locationData) async {
    try {
      final file = await _getQueueFile();
      String content = await file.exists() ? await file.readAsString() : '[]';
      List<dynamic> queue = jsonDecode(content);
      queue.add(locationData);
      await file.writeAsString(jsonEncode(queue));
    } catch (e) {
      print("Error escribiendo en la cola: $e");
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || !_isOnline) return;
    _isProcessingQueue = true;
    print("Procesando cola de ubicaciones offline...");

    try {
      final file = await _getQueueFile();
      if (!await file.exists()) {
        _isProcessingQueue = false;
        return;
      }

      String content = await file.readAsString();
      if (content.isEmpty || content == '[]') {
        _isProcessingQueue = false;
        return;
      }

      List<dynamic> queue = jsonDecode(content);
      List<dynamic> remainingQueue = List.from(queue);

      for (var item in queue) {
        final success = await _sendToFirebase(item as Map<String, dynamic>);
        if (success) {
          remainingQueue.remove(item);
        } else {
          // Stop processing if one fails, to maintain order
          break;
        }
      }

      await file.writeAsString(jsonEncode(remainingQueue));
      print("Procesamiento de cola finalizado. Quedan ${remainingQueue.length} elementos.");

    } catch (e) {
      print("Error procesando la cola: $e");
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<bool> _sendToFirebase(Map<String, dynamic> locationData) async {
    if (_user == null) return false;
    final deviceId = _user!.uid;
    final timestamp = locationData['timestamp'];

    try {
      await _db.ref('ubicaciones/$deviceId/$timestamp').set(locationData);
      await _db.ref('dispositivos/$deviceId/ultima_ubicacion').set(locationData);
      return true;
    } catch (e) {
      print("Error enviando a Firebase: $e");
      return false;
    }
  }

  // ... (stop method needs to cancel the new subscription) ...
  @override
  void stop() {
    _positionStream?.cancel();
    _configSubscription?.cancel();
    _connectivitySubscription?.cancel();
    print("Servicio de ubicación detenido.");
  }
}
