import 'package:flutter/material.dart';

class MapaScreen extends StatelessWidget {
  const MapaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
      ),
      body: const Center(
        child: Text(
          'Tela de mapa será implementada na próxima etapa.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}