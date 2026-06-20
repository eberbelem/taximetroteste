import 'dart:math';
import 'models/trip.dart';

class GpsFilter {
  static const double velocidadeMinimaMovimento = 0.83; // 3 km/h em m/s
  static const double velocidadeMaximaUrbana = 44.44; // 160 km/h em m/s
  static const double aceleracaoMaximaUrbana = 15.0; // m/s² (freagem brusca)

  TripPoint? ultimoPontoValido;

  GpsFilter({this.ultimoPontoValido});

  bool estaParado(double velocidadeMs) =>
      velocidadeMs < velocidadeMinimaMovimento;

  bool isVelocidadeAbsurda(double distanciaMetros, double intervaloSegundos) {
    if (intervaloSegundos <= 0) return true;
    final velocidadeCalculada = distanciaMetros / intervaloSegundos;
    return velocidadeCalculada > velocidadeMaximaUrbana;
  }

  bool isAceleracaoAbsurda(
      double velocidadeAtual, double velocidadeAnterior, double dt) {
    if (dt <= 0) return false;
    final aceleracao = (velocidadeAtual - velocidadeAnterior).abs() / dt;
    return aceleracao > aceleracaoMaximaUrbana;
  }

  TripPoint? filtrar({
    required double latitude,
    required double longitude,
    required double velocidade,
    required DateTime timestamp,
    double? acelerometroMagnitude,
  }) {
    final ponto = TripPoint(
      latitude: latitude,
      longitude: longitude,
      velocidade: velocidade,
      timestamp: timestamp,
    );

    if (ultimoPontoValido == null) {
      ultimoPontoValido = ponto;
      return ponto;
    }

    final dt = timestamp.difference(ultimoPontoValido!.timestamp).inSeconds;
    if (dt <= 0) return null;

    final distancia = _calcularDistanciaHaversine(
      ultimoPontoValido!.latitude,
      ultimoPontoValido!.longitude,
      latitude,
      longitude,
    );

    final estaParadoPelaVelocidade = estaParado(velocidade);

    final estaParadoPeloSensor = acelerometroMagnitude != null &&
        acelerometroMagnitude < 0.5;

    final veiculoParado = estaParadoPelaVelocidade || estaParadoPeloSensor;

    if (veiculoParado && distancia > 0.5) {
      return TripPoint(
        latitude: ultimoPontoValido!.latitude,
        longitude: ultimoPontoValido!.longitude,
        velocidade: 0.0,
        timestamp: timestamp,
      );
    }

    if (isVelocidadeAbsurda(distancia, dt.toDouble())) {
      return TripPoint(
        latitude: ultimoPontoValido!.latitude,
        longitude: ultimoPontoValido!.longitude,
        velocidade: velocidade,
        timestamp: timestamp,
      );
    }

    if (ultimoPontoValido != null &&
        isAceleracaoAbsurda(velocidade, ultimoPontoValido!.velocidade, dt.toDouble())) {
      return TripPoint(
        latitude: ultimoPontoValido!.latitude,
        longitude: ultimoPontoValido!.longitude,
        velocidade: ultimoPontoValido!.velocidade,
        timestamp: timestamp,
      );
    }

    ultimoPontoValido = ponto;
    return ponto;
  }

  double _calcularDistanciaHaversine(
      double lat1, double lon1, double lat2, double lon2) {
    const raioTerra = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return raioTerra * c;
  }

  double _toRadians(double degree) => degree * pi / 180.0;
}
