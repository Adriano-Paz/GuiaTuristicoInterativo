import 'package:flutter/material.dart';
import 'package:roteirodovinho/controllers/auth_controller.dart';
import 'login_screen.dart';

class Home_Screen extends StatelessWidget {
  const Home_Screen({super.key});

  Future<void> sair(BuildContext context) async {
    final authController = AuthController();

    await authController.logout();

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthController().usuarioAtual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roteiro do Vinho'),
        actions: [
          IconButton(
            onPressed: () => sair(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (usuario?.photoURL != null)
                CircleAvatar(
                  radius: 45,
                  backgroundImage: NetworkImage(usuario!.photoURL!),
                ),

              const SizedBox(height: 20),

              Text(
                'Bem-vindo!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 8),

              Text(
                usuario?.displayName ?? 'Usuário',
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 8),

              Text(
                usuario?.email ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: () => sair(context),
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}