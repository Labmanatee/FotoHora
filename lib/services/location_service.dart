import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

class LocationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  User? _user;
  DatabaseReference? _userRef;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    debugPrint("INFO: Iniciando LocationService con BackgroundGeolocation...");

    bool signedIn = await _signInAnonymously();
    if (!signedIn) {
      debugPrint("ERROR CRÍTICO: La autenticación falló. El servicio no puede continuar.");
      return;
    }
    _userRef = _database.ref('devices/${_user!.uid}');

    _initBackgroundGeolocation();
    _isInitialized = true;
  }

  void _initBackgroundGeolocation() {
    bg.BackgroundGeolocation.onLocation(_onLocation, _onLocationError);
    bg.BackgroundGeolocation.onConnectivityChange(_onConnectivityChange);

    bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 10,
      stopOnTerminate: false,
      startOnBoot: true,
      foregroundService: true,
      notification: bg.Notification(
        title: "Fotohora Tracker",
        text: "Servicio de ubicación en funcionamiento",
      ),
      logLevel: bg.Config.LOG_LEVEL_VERBOSE,
      stopTimeout: 5,
      stationaryRadius: 25,
    )).then((bg.State state) {
      if (!state.enabled) {
        bg.BackgroundGeolocation.start();
        debugPrint("INFO: Servicio BackgroundGeolocation iniciado.");
      }
    });
  }

  void _onLocation(bg.Location location) {
    debugPrint('[onLocation] - ${location.coords.latitude}, ${location.coords.longitude}');
    _processLocation(location);
  }

  void _onLocationError(bg.LocationError error) {
    debugPrint('[onLocation] ERROR - $error');
  }

  void _onConnectivityChange(bg.ConnectivityChangeEvent event) {
    debugPrint('[onConnectivityChange] - connected: ${event.connected}');
    _updateConnectionStatus(event.connected);
  }

  Future<void> _processLocation(bg.Location location) async {
    final locationData = {
      'lat': location.coords.latitude,
      'lng': location.coords.longitude,
      'speed': location.coords.speed,
      'accuracy': location.coords.accuracy,
      'timestamp': location.timestamp,
    };
    await _sendToFirebase(locationData);
  }

  Future<void> _sendToFirebase(Map<String, dynamic> data) async {
    if (_userRef == null) return;
    try {
      await _userRef!.child('locations').push().set(data);
      await _userRef!.child('last_location').set(data);
      debugPrint("INFO: Datos de ubicación enviados a Firebase.");
    } catch (e) {
      debugPrint("ERROR: Error al enviar datos a Firebase: $e");
    }
  }

  Future<void> _updateConnectionStatus(bool isOnline) async {
    if (_userRef == null) return;
    try {
      await _userRef!.child('status').set({
        'online': isOnline,
        'timestamp': DateTime.now().toIso8601String(),
      });
      debugPrint("INFO: Estado de conexión en Firebase actualizado a: ${isOnline ? 'Online' : 'Offline'}");
    } catch (e) {
      debugPrint("ERROR: No se pudo actualizar el estado de conexión: $e");
    }
  }

  void dispose() {
    bg.BackgroundGeolocation.stop();
    _updateConnectionStatus(false);
    _isInitialized = false;
    debugPrint("INFO: Servicio de ubicación detenido y limpiado.");
  }

  Future<bool> _signInAnonymously() async {
    try {
      if (_auth.currentUser != null) {
        _user = _auth.currentUser;
        return true;
      }
      final userCredential = await _auth.signInAnonymously();
      _user = userCredential.user;
      return _user != null;
    } catch (e) {
      debugPrint("ERROR: Error al intentar autenticar anónimamente: $e");
      return false;
    }
  }
}
