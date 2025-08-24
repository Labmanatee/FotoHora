import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'home_page.dart'; // RUTA CORREGIDA
import 'registration_screen.dart'; // RUTA CORREGIDA

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        user = userCredential.user;
      }

      if (user == null) {
        throw Exception("No se pudo obtener un ID de usuario.");
      }

      final profileRef = FirebaseDatabase.instance.ref('devices/${user.uid}/profile');
      final snapshot = await profileRef.get();

      if (!mounted) return;

      if (snapshot.exists) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage(cameras: widget.cameras)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => RegistrationScreen(cameras: widget.cameras)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error crítico: ${e.toString()}. Revisa la conexión a Firebase.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Verificando registro..."),
          ],
        ),
      ),
    );
  }
}
