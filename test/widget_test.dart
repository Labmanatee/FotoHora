import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fotohora_tracker/ui/home_page.dart';
import 'package:fotohora_tracker/ui/registration_screen.dart';

void main() {
  // Mock camera description needed for the widgets
  final mockCameras = [
    const CameraDescription(
      name: 'cam0',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    ),
  ];

  // Test group for individual screen rendering
  group('Screen Rendering Tests', () {

    testWidgets('RegistrationScreen builds without crashing', (WidgetTester tester) async {
      // Provide the necessary MaterialApp ancestor.
      await tester.pumpWidget(MaterialApp(
        home: RegistrationScreen(cameras: mockCameras),
      ));

      // Verify that the title and a key field are present.
      expect(find.text('Registro de Técnico'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Nombre Completo'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Registrar'), findsOneWidget);
    });

    testWidgets('HomePage builds without crashing', (WidgetTester tester) async {
      // Build HomePage directly.
      await tester.pumpWidget(MaterialApp(
        home: HomePage(cameras: mockCameras),
      ));

      // Verify that the title and the three main buttons are present.
      expect(find.text('Fotohora Tracker'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Tomar Foto / Video'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Generar Reporte'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Solicitar Salida / Descanso'), findsOneWidget);
    });

  });
}
