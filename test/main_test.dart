// test/main_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import para simular respuestas de red para Image.network
import 'package:network_image_mock/network_image_mock.dart';

// Imports de tu propio proyecto
import 'package:proyectomovilesii/models/noticia_model.dart';
import 'package:proyectomovilesii/screens/noticias_screen.dart';
import 'package:proyectomovilesii/screens/noticia_detalle_screen.dart';

void main() {
  // --- PRUEBA 1: Modelo ---
  group('Pruebas del Modelo Noticia', () {
    test('Debe crear una instancia de Noticia desde un DocumentSnapshot válido',
        () async {
      final firestore = FakeFirebaseFirestore();
      final fakeData = {
        'titulo': 'Prueba de Título',
        'fecha': '25/05/2024',
        'hora': '10:00',
        'enlace': 'http://ejemplo.com',
        'lugar': 'Tacna',
        'imagen_url': 'http://ejemplo.com/imagen.jpg',
        'resumen': 'Este es un resumen de prueba.',
        'contenido': 'Contenido',
        'tipo': 'Seguridad',
        'nivel': 'Alto',
      };
      final snapshot = await firestore
          .collection('noticias')
          .add(fakeData)
          .then((doc) => doc.get());
      final noticia = Noticia.fromFirestore(snapshot);
      expect(noticia.titulo, 'Prueba de Título');
      expect(noticia.resumen, 'Este es un resumen de prueba.');
    });
  });

  // --- PRUEBAS 2 y 3: Widgets ---
  group('Pruebas de Widget para NoticiasScreen', () {
    late FakeFirebaseFirestore fakeFirestore;
    final noticia1 = {
      'titulo': 'Simulacro de Sismo en la Ciudad',
      'resumen': 'Autoridades anuncian gran simulacro.',
      'fecha': '26/05/2024',
      'hora': '09:00',
      'enlace': '',
      'lugar': 'Plaza de Armas',
      'imagen_url': 'https://via.placeholder.com/150',
      'contenido': '',
      'tipo': 'Prevención',
      'nivel': 'Medio',
      'timestamp_creacion': DateTime.now().subtract(const Duration(days: 1)),
    };
    final noticia2 = {
      'titulo': 'Nuevas Cámaras de Seguridad Instaladas',
      'resumen': 'Se refuerza la vigilancia en zonas clave.',
      'fecha': '25/05/2024',
      'hora': '15:30',
      'enlace': '',
      'lugar': 'Av. Bolognesi',
      'imagen_url': 'https://via.placeholder.com/150',
      'contenido': '',
      'tipo': 'Tecnología',
      'nivel': 'Bajo',
      'timestamp_creacion': DateTime.now().subtract(const Duration(days: 2)),
    };

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('Noticias').add(noticia1);
      await fakeFirestore.collection('Noticias').add(noticia2);
    });

    // PRUEBA 2: Carga de datos
    testWidgets(
        'Debe mostrar CircularProgressIndicator y luego la lista de noticias',
        (WidgetTester tester) async {
      // mockNetworkImagesFor envuelve la prueba para que Image.network no falle.
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(
          home: NoticiasScreen(firestoreInstance: fakeFirestore),
        ));

        // Fase 1: Verificar el indicador de carga.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Avanzar el tiempo hasta que la carga se complete.
        await tester.pumpAndSettle();

        // Fase 2: Verificar que el indicador desapareció y la lista apareció.
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Simulacro de Sismo en la Ciudad'), findsOneWidget);
        expect(find.text('Nuevas Cámaras de Seguridad Instaladas'),
            findsOneWidget);
        expect(
            find.byType(Card), findsNWidgets(2)); // Debe encontrar 2 tarjetas.
      });
    });

    // PRUEBA 3: Navegación
    testWidgets(
        'Debe navegar a NoticiaDetalleScreen al hacer tap en una noticia',
        (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(
          home: NoticiasScreen(firestoreInstance: fakeFirestore),
          // Definimos una ruta para que la navegación de prueba funcione.
          routes: {
            '/noticia_detalle': (context) => NoticiaDetalleScreen(
                  noticia: Noticia(
                      id: 'test',
                      titulo: 'Detalle',
                      fecha: '',
                      hora: '',
                      enlace: '',
                      lugar: '',
                      imagen_url: '',
                      resumen: '',
                      contenido: '',
                      tipo: '',
                      nivel: ''),
                ),
          },
        ));

        // Esperamos que carguen las noticias.
        await tester.pumpAndSettle();

        // Verificamos que estamos en la pantalla correcta.
        expect(find.byType(NoticiasScreen), findsOneWidget);

        // Buscamos la primera tarjeta por su Key y le hacemos tap.
        await tester.tap(find.byKey(const Key('noticia_card_0')));

        // Esperamos a que la animación de navegación termine.
        await tester.pumpAndSettle();

        // Verificamos que hemos navegado a la pantalla de detalle.
        expect(find.byType(NoticiaDetalleScreen), findsOneWidget);
      });
    });
  });
}
