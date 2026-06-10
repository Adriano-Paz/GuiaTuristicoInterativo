import 'package:flutter/material.dart';

import '../data/estabelecimentos_data.dart';
import '../models/estabelecimento_model.dart';
import '../services/roteiro_store.dart';
import 'detalhes_estabelecimento_screen.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  final RoteiroStore _store = RoteiroStore.instance;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  void abrirDetalhes(Estabelecimento estabelecimento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetalhesEstabelecimentoScreen(estabelecimento: estabelecimento),
      ),
    );
  }

  Future<void> removerFavorito(Estabelecimento estabelecimento) async {
    await _store.alternarFavorito(estabelecimento);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${estabelecimento.nome} removido dos favoritos.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final favoritos = _store.favoritosEm(estabelecimentosData);

        return Scaffold(
          appBar: AppBar(title: const Text('Favoritos')),
          body: favoritos.isEmpty
              ? const _FavoritosVazio()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoritos.length,
                  itemBuilder: (context, index) {
                    final estabelecimento = favoritos[index];
                    return _FavoritoCard(
                      estabelecimento: estabelecimento,
                      nota: _store.notaMedia(estabelecimento),
                      onTap: () => abrirDetalhes(estabelecimento),
                      onRemover: () => removerFavorito(estabelecimento),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _FavoritosVazio extends StatelessWidget {
  const _FavoritosVazio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 70,
              color: Colors.purple.shade200,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum favorito salvo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Os estabelecimentos favoritados ficam armazenados localmente para consulta mesmo sem internet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritoCard extends StatelessWidget {
  final Estabelecimento estabelecimento;
  final double nota;
  final VoidCallback onTap;
  final VoidCallback onRemover;

  const _FavoritoCard({
    required this.estabelecimento,
    required this.nota,
    required this.onTap,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Image.network(
              estabelecimento.imagemUrl,
              width: 116,
              height: 126,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 116,
                  height: 126,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            estabelecimento.nome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remover favorito',
                          onPressed: onRemover,
                          icon: const Icon(Icons.favorite),
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                    Text(
                      estabelecimento.categoria,
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          nota.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      estabelecimento.endereco,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
