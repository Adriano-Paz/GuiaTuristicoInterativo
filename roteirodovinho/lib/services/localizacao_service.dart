import 'package:geolocator/geolocator.dart';

class ResultadoLocalizacao {
  final Position? posicao;
  final String? erro;

  const ResultadoLocalizacao({this.posicao, this.erro});

  bool get sucesso => posicao != null;
}

class LocalizacaoService {
  static Future<ResultadoLocalizacao> obterLocalizacaoAtual() async {
    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!servicoAtivo) {
        return const ResultadoLocalizacao(
          erro: 'GPS desativado. Ative a localização do dispositivo.',
        );
      }

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied) {
        return const ResultadoLocalizacao(
          erro: 'Permissão de localização negada.',
        );
      }

      if (permissao == LocationPermission.deniedForever) {
        return const ResultadoLocalizacao(
          erro:
              'Permissão de localização negada permanentemente. Libere nas configurações do aparelho.',
        );
      }

      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return ResultadoLocalizacao(posicao: posicao);
    } catch (_) {
      return const ResultadoLocalizacao(
        erro: 'Não foi possível obter sua localização agora.',
      );
    }
  }
}
