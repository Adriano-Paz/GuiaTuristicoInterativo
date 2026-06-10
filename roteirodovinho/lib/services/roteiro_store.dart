import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/avaliacao_model.dart';
import '../models/estabelecimento_model.dart';

List<Map<String, dynamic>> _decodificarListaJson(String json) {
  final dados = jsonDecode(json) as List<dynamic>;
  return dados
      .whereType<Map<dynamic, dynamic>>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _codificarListaJson(List<Map<String, dynamic>> dados) {
  return jsonEncode(dados);
}

class RoteiroStore extends ChangeNotifier {
  RoteiroStore._();

  static final RoteiroStore instance = RoteiroStore._();

  static const _favoritosKey = 'favoritos_ids';
  static const _avaliacoesKey = 'avaliacoes_json';

  final Set<int> _favoritos = {};
  final List<Avaliacao> _avaliacoes = [];

  bool _carregado = false;
  Future<void>? _carregando;

  bool get carregado => _carregado;

  Future<void> load() {
    if (_carregado) return Future.value();
    return _carregando ??= _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final favoritosSalvos = prefs.getStringList(_favoritosKey) ?? [];
    _favoritos
      ..clear()
      ..addAll(favoritosSalvos.map(int.tryParse).whereType<int>());

    final avaliacoesJson = prefs.getString(_avaliacoesKey);
    _avaliacoes.clear();

    if (avaliacoesJson != null && avaliacoesJson.isNotEmpty) {
      try {
        final dados = await compute(_decodificarListaJson, avaliacoesJson);
        _avaliacoes.addAll(dados.map(Avaliacao.fromJson));
      } catch (_) {
        _avaliacoes.clear();
      }
    }

    _carregado = true;
    notifyListeners();
  }

  bool isFavorito(int estabelecimentoId) {
    return _favoritos.contains(estabelecimentoId);
  }

  List<Estabelecimento> favoritosEm(List<Estabelecimento> locais) {
    return locais.where((local) => isFavorito(local.id)).toList();
  }

  Future<void> alternarFavorito(Estabelecimento estabelecimento) async {
    if (_favoritos.contains(estabelecimento.id)) {
      _favoritos.remove(estabelecimento.id);
    } else {
      _favoritos.add(estabelecimento.id);
    }

    notifyListeners();
    await _salvarFavoritos();
  }

  List<Avaliacao> avaliacoesDo(int estabelecimentoId) {
    final avaliacoes = _avaliacoes
        .where((avaliacao) => avaliacao.estabelecimentoId == estabelecimentoId)
        .toList();

    avaliacoes.sort((a, b) => b.criadaEm.compareTo(a.criadaEm));
    return avaliacoes;
  }

  double notaMedia(Estabelecimento estabelecimento) {
    final avaliacoes = avaliacoesDo(estabelecimento.id);
    if (avaliacoes.isEmpty) return estabelecimento.nota;

    final somaAvaliacoes = avaliacoes.fold<double>(
      0,
      (total, avaliacao) => total + avaliacao.nota,
    );

    return (estabelecimento.nota + somaAvaliacoes) / (avaliacoes.length + 1);
  }

  Future<void> adicionarAvaliacao(Avaliacao avaliacao) async {
    _avaliacoes.add(avaliacao);

    try {
      await _salvarAvaliacoes();
      notifyListeners();
    } catch (_) {
      _avaliacoes.remove(avaliacao);
      rethrow;
    }
  }

  Future<void> _salvarFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _favoritos.map((id) => id.toString()).toList()..sort();
    await prefs.setStringList(_favoritosKey, ids);
  }

  Future<void> _salvarAvaliacoes() async {
    final prefs = await SharedPreferences.getInstance();
    final dados = _avaliacoes.map((avaliacao) => avaliacao.toJson()).toList();
    final json = await compute(_codificarListaJson, dados);
    await prefs.setString(_avaliacoesKey, json);
  }
}
