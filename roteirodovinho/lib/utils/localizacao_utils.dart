import 'package:geolocator/geolocator.dart';

import '../models/estabelecimento_model.dart';

double calcularDistanciaMetros({
  required double origemLatitude,
  required double origemLongitude,
  required Estabelecimento destino,
}) {
  return Geolocator.distanceBetween(
    origemLatitude,
    origemLongitude,
    destino.latitude,
    destino.longitude,
  );
}

String formatarDistancia(double metros) {
  if (metros >= 1000) {
    return '${(metros / 1000).toStringAsFixed(1)} km';
  }

  return '${metros.round()} m';
}
