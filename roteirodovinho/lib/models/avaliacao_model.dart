class Avaliacao {
  final int estabelecimentoId;
  final double nota;
  final String comentario;
  final String? fotoBase64;
  final DateTime criadaEm;

  const Avaliacao({
    required this.estabelecimentoId,
    required this.nota,
    required this.comentario,
    required this.criadaEm,
    this.fotoBase64,
  });

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    return Avaliacao(
      estabelecimentoId: json['estabelecimentoId'] as int,
      nota: (json['nota'] as num).toDouble(),
      comentario: json['comentario'] as String,
      fotoBase64: json['fotoBase64'] as String?,
      criadaEm: DateTime.parse(json['criadaEm'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estabelecimentoId': estabelecimentoId,
      'nota': nota,
      'comentario': comentario,
      'fotoBase64': fotoBase64,
      'criadaEm': criadaEm.toIso8601String(),
    };
  }
}
