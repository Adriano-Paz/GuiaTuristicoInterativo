import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/avaliacao_model.dart';
import '../models/estabelecimento_model.dart';
import '../services/localizacao_service.dart';
import '../services/roteiro_store.dart';
import '../utils/localizacao_utils.dart';

String _codificarFotoBase64(Uint8List bytes) => base64Encode(bytes);

Uint8List _decodificarFotoBase64(String foto) => base64Decode(foto);

class DetalhesEstabelecimentoScreen extends StatefulWidget {
  final Estabelecimento estabelecimento;

  const DetalhesEstabelecimentoScreen({
    super.key,
    required this.estabelecimento,
  });

  @override
  State<DetalhesEstabelecimentoScreen> createState() =>
      _DetalhesEstabelecimentoScreenState();
}

class _DetalhesEstabelecimentoScreenState
    extends State<DetalhesEstabelecimentoScreen> {
  final RoteiroStore _store = RoteiroStore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  Position? posicaoAtual;
  String? erroLocalizacao;
  bool carregandoLocalizacao = false;

  @override
  void initState() {
    super.initState();
    _store.load();
    obterLocalizacaoAtual();
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
  }

  double? get distancia {
    final posicao = posicaoAtual;
    if (posicao == null) return null;

    return calcularDistanciaMetros(
      origemLatitude: posicao.latitude,
      origemLongitude: posicao.longitude,
      destino: widget.estabelecimento,
    );
  }

  Future<void> abrirRota() async {
    final destino =
        '${widget.estabelecimento.latitude},${widget.estabelecimento.longitude}';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destino&travelmode=driving',
    );

    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted || abriu) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o app de mapas.')),
    );
  }

  Future<void> alternarFavorito() async {
    await _store.alternarFavorito(widget.estabelecimento);

    if (!mounted) return;

    final favorito = _store.isFavorito(widget.estabelecimento.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          favorito
              ? 'Local adicionado aos favoritos.'
              : 'Local removido dos favoritos.',
        ),
      ),
    );
  }

  Future<void> abrirDialogoAvaliacao() async {
    final comentarioController = TextEditingController();
    double nota = 5;
    Uint8List? fotoBytes;
    String? erroFormulario;
    String? erroFoto;
    bool salvando = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              Future<void> selecionarFoto() async {
                try {
                  final foto = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 35,
                    maxHeight: 720,
                    maxWidth: 720,
                  );

                  if (foto == null) return;

                  final bytes = await foto.readAsBytes();

                  if (!dialogContext.mounted) return;

                  setDialogState(() {
                    fotoBytes = bytes;
                    erroFoto = null;
                  });
                } catch (_) {
                  if (!dialogContext.mounted) return;

                  setDialogState(() {
                    erroFoto =
                        'Não foi possível acessar a câmera. Verifique a permissão.';
                  });
                }
              }

              Future<void> salvarAvaliacao() async {
                final comentario = comentarioController.text.trim();

                if (nota <= 0 || comentario.isEmpty) {
                  setDialogState(() {
                    erroFormulario =
                        'Informe uma nota e escreva um comentário.';
                  });
                  return;
                }

                setDialogState(() {
                  salvando = true;
                  erroFormulario = null;
                });

                try {
                  final fotoBase64 = fotoBytes == null
                      ? null
                      : await compute(_codificarFotoBase64, fotoBytes!);

                  final avaliacao = Avaliacao(
                    estabelecimentoId: widget.estabelecimento.id,
                    nota: nota,
                    comentario: comentario,
                    fotoBase64: fotoBase64,
                    criadaEm: DateTime.now(),
                  );

                  await _store.adicionarAvaliacao(avaliacao);

                  if (!mounted || !dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Avaliação salva.')),
                  );
                } catch (_) {
                  if (!dialogContext.mounted) return;

                  setDialogState(() {
                    salvando = false;
                    erroFormulario =
                        'Não foi possível salvar a avaliação. Tente novamente.';
                  });
                }
              }

              return AlertDialog(
                title: const Text('Avaliar estabelecimento'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: RatingBar.builder(
                          initialRating: nota,
                          minRating: 1,
                          itemCount: 5,
                          itemSize: 36,
                          itemBuilder: (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (valor) {
                            nota = valor;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: comentarioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Comentário',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: salvando ? null : selecionarFoto,
                        icon: const Icon(Icons.photo_camera),
                        label: Text(
                          fotoBytes == null ? 'Anexar foto' : 'Trocar foto',
                        ),
                      ),
                      if (fotoBytes != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            fotoBytes!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      if (erroFoto != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          erroFoto!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                      if (erroFormulario != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          erroFormulario!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: salvando
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton.icon(
                    onPressed: salvando ? null : salvarAvaliacao,
                    icon: salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Salvar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      _descartarComentarioController(comentarioController);
    }
  }

  void _descartarComentarioController(TextEditingController controller) {
    Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final favorito = _store.isFavorito(widget.estabelecimento.id);
        final notaMedia = _store.notaMedia(widget.estabelecimento);
        final avaliacoes = _store.avaliacoesDo(widget.estabelecimento.id);

        return Scaffold(
          appBar: AppBar(title: Text(widget.estabelecimento.nome)),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Image.network(
                      widget.estabelecimento.imagemUrl,
                      height: 230,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 230,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: favorito
                              ? 'Remover dos favoritos'
                              : 'Adicionar aos favoritos',
                          onPressed: alternarFavorito,
                          color: favorito ? Colors.redAccent : Colors.white,
                          icon: Icon(
                            favorito ? Icons.favorite : Icons.favorite_border,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.estabelecimento.nome,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        widget.estabelecimento.categoria,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text(
                            notaMedia.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' (${avaliacoes.length} avaliação${avaliacoes.length == 1 ? '' : 'ões'} locais)',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _SecaoInfo(
                        titulo: 'Descrição',
                        conteudo: widget.estabelecimento.descricao,
                      ),

                      const SizedBox(height: 20),

                      _SecaoInfo(
                        titulo: 'Endereço',
                        conteudo: widget.estabelecimento.endereco,
                      ),

                      const SizedBox(height: 20),

                      _SecaoDistancia(
                        carregando: carregandoLocalizacao,
                        erro: erroLocalizacao,
                        distancia: distancia,
                        onTentarNovamente: obterLocalizacaoAtual,
                      ),

                      const SizedBox(height: 20),

                      _SecaoInfo(
                        titulo: 'Contato',
                        conteudo: widget.estabelecimento.telefone,
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: abrirRota,
                          icon: const Icon(Icons.route),
                          label: const Text('Como chegar'),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: alternarFavorito,
                          icon: Icon(
                            favorito ? Icons.favorite : Icons.favorite_border,
                          ),
                          label: Text(
                            favorito
                                ? 'Remover dos favoritos'
                                : 'Adicionar aos favoritos',
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      _AvaliacoesSection(
                        avaliacoes: avaliacoes,
                        onAvaliar: abrirDialogoAvaliacao,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SecaoInfo extends StatelessWidget {
  final String titulo;
  final String conteudo;

  const _SecaoInfo({required this.titulo, required this.conteudo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(conteudo, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

class _SecaoDistancia extends StatelessWidget {
  final bool carregando;
  final String? erro;
  final double? distancia;
  final VoidCallback onTentarNovamente;

  const _SecaoDistancia({
    required this.carregando,
    required this.erro,
    required this.distancia,
    required this.onTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    Widget conteudo;

    if (carregando) {
      conteudo = const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Obtendo localização...'),
        ],
      );
    } else if (erro != null) {
      conteudo = Row(
        children: [
          Expanded(
            child: Text(erro!, style: TextStyle(color: Colors.orange.shade900)),
          ),
          TextButton(onPressed: onTentarNovamente, child: const Text('Tentar')),
        ],
      );
    } else {
      final distanciaTexto = distancia == null
          ? 'Distância indisponível'
          : '${formatarDistancia(distancia!)} de você';

      conteudo = Row(
        children: [
          const Icon(Icons.near_me_outlined, size: 20),
          const SizedBox(width: 8),
          Text(distanciaTexto, style: const TextStyle(fontSize: 16)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distância',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        conteudo,
      ],
    );
  }
}

class _AvaliacoesSection extends StatelessWidget {
  final List<Avaliacao> avaliacoes;
  final VoidCallback onAvaliar;

  const _AvaliacoesSection({required this.avaliacoes, required this.onAvaliar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Avaliações',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: onAvaliar,
              icon: const Icon(Icons.rate_review),
              label: const Text('Avaliar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (avaliacoes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('Nenhuma avaliação local cadastrada.'),
          )
        else
          ...avaliacoes.map(
            (avaliacao) => _AvaliacaoCard(avaliacao: avaliacao),
          ),
      ],
    );
  }
}

class _AvaliacaoCard extends StatelessWidget {
  final Avaliacao avaliacao;

  const _AvaliacaoCard({required this.avaliacao});

  String get dataFormatada {
    final data = avaliacao.criadaEm.toLocal();
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year} $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final foto = avaliacao.fotoBase64;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RatingBarIndicator(
                  rating: avaliacao.nota,
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 20,
                ),
                const Spacer(),
                Text(
                  dataFormatada,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(avaliacao.comentario),
            if (foto != null && foto.isNotEmpty) ...[
              const SizedBox(height: 12),
              _FotoAvaliacao(fotoBase64: foto),
            ],
          ],
        ),
      ),
    );
  }
}

class _FotoAvaliacao extends StatefulWidget {
  final String fotoBase64;

  const _FotoAvaliacao({required this.fotoBase64});

  @override
  State<_FotoAvaliacao> createState() => _FotoAvaliacaoState();
}

class _FotoAvaliacaoState extends State<_FotoAvaliacao> {
  late Future<Uint8List?> _fotoFuture;

  @override
  void initState() {
    super.initState();
    _fotoFuture = _carregarFoto();
  }

  @override
  void didUpdateWidget(covariant _FotoAvaliacao oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.fotoBase64 != widget.fotoBase64) {
      _fotoFuture = _carregarFoto();
    }
  }

  Future<Uint8List?> _carregarFoto() async {
    try {
      return await compute(_decodificarFotoBase64, widget.fotoBase64);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _fotoFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;

        if (bytes == null) {
          return Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : const Center(child: Icon(Icons.broken_image_outlined)),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            bytes,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        );
      },
    );
  }
}
