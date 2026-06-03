import 'package:flutter/material.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
      ),
      body: const Center(
        child: Text(
          'Tela de favoritos será implementada na próxima etapa.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}