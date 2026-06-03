import 'package:flutter/material.dart';
import 'package:roteirodovinho/controllers/auth_controller.dart';

import '../models/estabelecimento_model.dart';
import 'detalhes_estabelecimento_screen.dart';
import 'favoritos_screen.dart';
import 'login_screen.dart';
import 'mapa_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = AuthController();
  final TextEditingController _buscaController = TextEditingController();

  String busca = '';
  String categoriaSelecionada = 'Todos';

  final List<Estabelecimento> estabelecimentos = [
    Estabelecimento(
      id: 1,
      nome: 'Vinícola Góes',
      categoria: 'Vinícola',
      descricao:
          'Uma das vinícolas mais conhecidas de São Roque, com visitação, loja de vinhos e área gastronômica.',
      endereco: 'Estrada do Vinho, São Roque - SP',
      nota: 4.8,
      imagemUrl:
          'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=900',
      latitude: -23.5293,
      longitude: -47.1357,
      telefone: '(11) 0000-0000',
    ),
    Estabelecimento(
      id: 2,
      nome: 'Quinta do Olivardo',
      categoria: 'Restaurante',
      descricao:
          'Restaurante tradicional do roteiro, conhecido pela gastronomia portuguesa e ambiente turístico.',
      endereco: 'Roteiro do Vinho, São Roque - SP',
      nota: 4.7,
      imagemUrl:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=900',
      latitude: -23.5305,
      longitude: -47.1370,
      telefone: '(11) 0000-0000',
    ),
    Estabelecimento(
      id: 3,
      nome: 'Vila Don Patto',
      categoria: 'Gastronomia',
      descricao:
          'Complexo turístico com restaurante, café, empório, lazer e espaços para fotos.',
      endereco: 'Estrada do Vinho, São Roque - SP',
      nota: 4.6,
      imagemUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=900',
      latitude: -23.5280,
      longitude: -47.1320,
      telefone: '(11) 0000-0000',
    ),
    Estabelecimento(
      id: 4,
      nome: 'Vinícola XV de Novembro',
      categoria: 'Vinícola',
      descricao:
          'Vinícola tradicional com venda de vinhos, sucos, queijos e produtos artesanais.',
      endereco: 'São Roque - SP',
      nota: 4.5,
      imagemUrl:
          'https://images.unsplash.com/photo-1528823872057-9c018a7a7553?w=900',
      latitude: -23.5271,
      longitude: -47.1390,
      telefone: '(11) 0000-0000',
    ),
  ];

  List<String> get categorias {
    final lista = estabelecimentos.map((e) => e.categoria).toSet().toList();
    lista.sort();
    return ['Todos', ...lista];
  }

  List<Estabelecimento> get estabelecimentosFiltrados {
    return estabelecimentos.where((local) {
      final textoBusca = busca.toLowerCase().trim();

      final combinaBusca =
          textoBusca.isEmpty ||
          local.nome.toLowerCase().contains(textoBusca) ||
          local.categoria.toLowerCase().contains(textoBusca) ||
          local.endereco.toLowerCase().contains(textoBusca);

      final combinaCategoria =
          categoriaSelecionada == 'Todos' ||
          local.categoria == categoriaSelecionada;

      return combinaBusca && combinaCategoria;
    }).toList();
  }

  Future<void> sair() async {
    await _authController.logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
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

  void abrirFavoritos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoritosScreen()),
    );
  }

  void abrirMapa() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapaScreen()),
    );
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _authController.usuarioAtual;

    return Scaffold(
      backgroundColor: Colors.purple.shade100,
      appBar: AppBar(
        title: const Text('Roteiro do Vinho'),
        actions: [
          IconButton(
            tooltip: 'Favoritos',
            onPressed: abrirFavoritos,
            icon: const Icon(Icons.favorite_border),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: sair,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: usuario?.photoURL != null
                            ? NetworkImage(usuario!.photoURL!)
                            : null,
                        child: usuario?.photoURL == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Olá, seja bem-vindo!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              usuario?.displayName ?? 'Usuário',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Explore os principais pontos do Roteiro do Vinho em São Roque.',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _buscaController,
                onChanged: (valor) {
                  setState(() {
                    busca = valor;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Buscar vinícola, restaurante ou local...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: busca.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _buscaController.clear();
                            setState(() {
                              busca = '';
                            });
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categorias.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final categoria = categorias[index];
                  final selecionada = categoria == categoriaSelecionada;

                  return ChoiceChip(
                    label: Text(categoria),
                    selected: selecionada,
                    onSelected: (_) {
                      setState(() {
                        categoriaSelecionada = categoria;
                      });
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: abrirMapa,
                      icon: const Icon(Icons.map),
                      label: const Text('Ver mapa'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: abrirFavoritos,
                      icon: const Icon(Icons.favorite),
                      label: const Text('Favoritos'),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: estabelecimentosFiltrados.isEmpty
                  ? const Center(
                      child: Text('Nenhum estabelecimento encontrado.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: estabelecimentosFiltrados.length,
                      itemBuilder: (context, index) {
                        final estabelecimento =
                            estabelecimentosFiltrados[index];

                        return _EstabelecimentoCard(
                          estabelecimento: estabelecimento,
                          onTap: () => abrirDetalhes(estabelecimento),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstabelecimentoCard extends StatelessWidget {
  final Estabelecimento estabelecimento;
  final VoidCallback onTap;

  const _EstabelecimentoCard({
    required this.estabelecimento,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  estabelecimento.imagemUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported, size: 44),
                    );
                  },
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          estabelecimento.nota.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estabelecimento.nome,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

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
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          estabelecimento.endereco,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Ver detalhes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
