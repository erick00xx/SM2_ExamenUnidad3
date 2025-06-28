// lib/screens/noticias_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/noticia_model.dart';
import 'noticia_detalle_screen.dart';

class NoticiasScreen extends StatefulWidget {
  // Inyección de dependencias para permitir pruebas con una BBDD falsa.
  final FirebaseFirestore? firestoreInstance;
  const NoticiasScreen({super.key, this.firestoreInstance});

  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  bool _isLoading = true;
  List<Noticia> _noticias = [];

  @override
  void initState() {
    super.initState();
    _cargarNoticias();
  }

  Future<void> _cargarNoticias() async {
    try {
      // Usa la instancia inyectada para pruebas, o la real en producción.
      final firestore = widget.firestoreInstance ?? FirebaseFirestore.instance;

      QuerySnapshot noticiasSnapshot = await firestore
          .collection('Noticias')
          .orderBy('timestamp_creacion', descending: true)
          .limit(20)
          .get();

      final noticiasData = noticiasSnapshot.docs
          .map((doc) => Noticia.fromFirestore(doc))
          .toList();

      if (mounted) {
        setState(() {
          _noticias = noticiasData;
          _isLoading = false;
        });
      }
    } catch (e) {
      // SOLUCIÓN: En caso de error, solo cambiamos el estado.
      // No se llama a nada que dependa del 'context' para evitar errores en initState.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Opcionalmente, puedes imprimir el error para depuración durante el desarrollo.
      // print('Error al cargar noticias: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias de la Comunidad'),
        backgroundColor: Colors.indigo[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _noticias.length,
              itemBuilder: (context, index) {
                final noticia = _noticias[index];
                // El widget Card con todos sus detalles y la Key para la prueba de tap.
                return Card(
                  key: Key(
                      'noticia_card_$index'), // Key para identificar el widget en pruebas.
                  elevation: 4.0,
                  margin: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 5.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NoticiaDetalleScreen(noticia: noticia),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NOTA: Image.network funcionará en las pruebas gracias
                        // al 'provideMockedNetworkImages' en el archivo de test.
                        Image.network(
                          noticia.imagen_url,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image_outlined,
                                    size: 50, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(noticia.titulo,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Text(noticia.resumen,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[700]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
