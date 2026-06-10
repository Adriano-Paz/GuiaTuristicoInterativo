import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/estabelecimentos_data.dart';
import '../models/estabelecimento_model.dart';
import '../services/localizacao_service.dart';
import '../utils/localizacao_utils.dart';
import 'detalhes_estabelecimento_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  static const LatLng _centroRoteiro = LatLng(-23.5295, -47.1355);

  final MapController _mapController = MapController();

  String categoriaSelecionada = 'Todos';
  Estabelecimento? estabelecimentoSelecionado;
  Position? posicaoAtual;
  String? erroLocalizacao;
  bool carregandoLocalizacao = false;

  List<String> get categorias {
    final lista = estabelecimentosData.map((e) => e.categoria).toSet().toList();
    lista.sort();
    return ['Todos', ...lista];
  }

  List<Estabelecimento> get estabelecimentosFiltrados {
    if (categoriaSelecionada == 'Todos') return estabelecimentosData;

    return estabelecimentosData
        .where((local) => local.categoria == categoriaSelecionada)
        .toList();
  }

  LatLng? get _pontoUsuario {
    final posicao = posicaoAtual;
    if (posicao == null) return null;
    return LatLng(posicao.latitude, posicao.longitude);
  }

  @override
  void initState() {
    super.initState();
    obterLocalizacaoAtual();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> obterLocalizacaoAtual() async {
    setState(() {
      carregandoLocalizacao = true;
      erroLocalizacao = null;
    });

    final resultado = await LocalizacaoService.obterLocalizacaoAtual();

    if (!mounted) return;

    setState(() {
      posicaoAtual = resultado.posicao;
      erroLocalizacao = resultado.erro;
      carregandoLocalizacao = false;
    });

    final ponto = _pontoUsuario;
    if (ponto != null) {
      _mapController.move(ponto, 14.5);
    }
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

  void centralizarRoteiro() {
    _mapController.move(_centroRoteiro, 13.8);
  }

  double? distanciaAte(Estabelecimento estabelecimento) {
    final posicao = posicaoAtual;
    if (posicao == null) return null;

    return calcularDistanciaMetros(
      origemLatitude: posicao.latitude,
      origemLongitude: posicao.longitude,
      destino: estabelecimento,
    );
  }

  List<Marker> criarMarcadores() {
    final marcadores = estabelecimentosFiltrados.map((local) {
      final selecionado = estabelecimentoSelecionado?.id == local.id;

      return Marker(
        point: LatLng(local.latitude, local.longitude),
        width: 56,
        height: 56,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () {
            setState(() {
              estabelecimentoSelecionado = local;
            });
          },
          child: Icon(
            Icons.location_on,
            size: selecionado ? 52 : 44,
            color: selecionado ? Colors.deepPurple : Colors.red.shade700,
            shadows: const [Shadow(color: Colors.white, blurRadius: 8)],
          ),
        ),
      );
    }).toList();

    final pontoUsuario = _pontoUsuario;
    if (pontoUsuario != null) {
      marcadores.add(
        Marker(
          point: pontoUsuario,
          width: 46,
          height: 46,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return marcadores;
  }

  @override
  Widget build(BuildContext context) {
    final selecionado = estabelecimentoSelecionado;

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa interativo')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centroRoteiro,
              initialZoom: 13.8,
              minZoom: 11,
              maxZoom: 18,
              onTap: (_, _) {
                setState(() {
                  estabelecimentoSelecionado = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.roteirodovinho',
              ),
              MarkerLayer(markers: criarMarcadores()),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _FiltrosMapa(
              categorias: categorias,
              selecionada: categoriaSelecionada,
              onSelecionar: (categoria) {
                setState(() {
                  categoriaSelecionada = categoria;
                  if (!estabelecimentosFiltrados.any(
                    (local) => local.id == estabelecimentoSelecionado?.id,
                  )) {
                    estabelecimentoSelecionado = null;
                  }
                });
              },
            ),
          ),
          if (erroLocalizacao != null)
            Positioned(
              top: 74,
              left: 12,
              right: 12,
              child: _MensagemMapa(
                mensagem: erroLocalizacao!,
                onTentarNovamente: obterLocalizacaoAtual,
              ),
            ),
          if (selecionado != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 18,
              child: _CardLocalMapa(
                estabelecimento: selecionado,
                distancia: distanciaAte(selecionado),
                onAbrir: () => abrirDetalhes(selecionado),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'localizacao',
            tooltip: 'Minha localização',
            onPressed: carregandoLocalizacao ? null : obterLocalizacaoAtual,
            child: carregandoLocalizacao
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'centroRoteiro',
            tooltip: 'Centralizar roteiro',
            onPressed: centralizarRoteiro,
            child: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
    );
  }
}

class _FiltrosMapa extends StatelessWidget {
  final List<String> categorias;
  final String selecionada;
  final ValueChanged<String> onSelecionar;

  const _FiltrosMapa({
    required this.categorias,
    required this.selecionada,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          scrollDirection: Axis.horizontal,
          itemCount: categorias.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final categoria = categorias[index];
            return ChoiceChip(
              label: Text(categoria),
              selected: categoria == selecionada,
              onSelected: (_) => onSelecionar(categoria),
            );
          },
        ),
      ),
    );
  }
}

class _MensagemMapa extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentarNovamente;

  const _MensagemMapa({
    required this.mensagem,
    required this.onTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange.shade900),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensagem,
                style: TextStyle(color: Colors.orange.shade900),
              ),
            ),
            TextButton(
              onPressed: onTentarNovamente,
              child: const Text('Tentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardLocalMapa extends StatelessWidget {
  final Estabelecimento estabelecimento;
  final double? distancia;
  final VoidCallback onAbrir;

  const _CardLocalMapa({
    required this.estabelecimento,
    required this.distancia,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    final distanciaTexto = distancia == null
        ? 'Distância indisponível'
        : 'A ${formatarDistancia(distancia!)} de você';

    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                estabelecimento.imagemUrl,
                width: 74,
                height: 74,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 74,
                    height: 74,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    estabelecimento.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    estabelecimento.categoria,
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.near_me, size: 17),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          distanciaTexto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Ver detalhes',
              onPressed: onAbrir,
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}
