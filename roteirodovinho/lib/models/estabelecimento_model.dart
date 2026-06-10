class Estabelecimento {
  final int id;
  final String nome;
  final String categoria;
  final String descricao;
  final String endereco;
  final double nota;
  final String imagemUrl;
  final double latitude;
  final double longitude;
  final String telefone;

  const Estabelecimento({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.descricao,
    required this.endereco,
    required this.nota,
    required this.imagemUrl,
    required this.latitude,
    required this.longitude,
    required this.telefone,
  });
}
