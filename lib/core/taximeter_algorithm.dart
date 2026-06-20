import 'dart:async';
import 'dart:math';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'models/fare_table.dart';
import 'models/trip.dart';
import 'gps_filter.dart';

class TaximeterAlgorithm {
  final FareTable fareTable;
  Trip? tripAtual;
  GpsFilter? gpsFilter;
  Timer? _timer;

  TripPoint? ultimoPontoProcessado;

  final _onValorAtualizado = StreamController<double>.broadcast();
  final _onDistanciaAtualizada = StreamController<double>.broadcast();
  final _onTempoAtualizado = StreamController<Duration>.broadcast();
  final _onStatusChanged = StreamController<TripStatus>.broadcast();
  final _onFracaoAtualizada = StreamController<int>.broadcast();

  Stream<double> get onValorAtualizado => _onValorAtualizado.stream;
  Stream<double> get onDistanciaAtualizada => _onDistanciaAtualizada.stream;
  Stream<Duration> get onTempoAtualizado => _onTempoAtualizado.stream;
  Stream<TripStatus> get onStatusChanged => _onStatusChanged.stream;
  Stream<int> get onFracaoAtualizada => _onFracaoAtualizada.stream;

  TaximeterAlgorithm({required this.fareTable});

  bool get estaEmCorrida =>
      tripAtual != null && tripAtual!.status == TripStatus.emAndamento;

  int get nf => tripAtual?.nf ?? 0;
  double get valorTotal => tripAtual?.valorTotal ?? 0.0;

  void iniciarCorrida({String? tripId, int tarifaInicial = 1}) {
    tripAtual = Trip(
      id: tripId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fareTable: fareTable,
      inicio: DateTime.now(),
      status: TripStatus.emAndamento,
      nf: 1,
      tarifaAtiva: tarifaInicial,
    );
    gpsFilter = GpsFilter();
    ultimoPontoProcessado = null;

    _onValorAtualizado.add(tripAtual!.valorTotal);
    _onFracaoAtualizada.add(1);
    _onStatusChanged.add(TripStatus.emAndamento);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _executarCiclo);
  }

  void alternarTarifa({int? tarifa}) {
    if (tripAtual == null) return;
    tripAtual!.tarifaAtiva = tarifa ?? (tripAtual!.tarifaAtiva == 1 ? 2 : 1);
  }

  void encerrarCorrida() {
    _timer?.cancel();
    _timer = null;
    if (tripAtual != null) {
      tripAtual!.fim = DateTime.now();
      tripAtual!.status = TripStatus.encerrada;
      _onStatusChanged.add(TripStatus.encerrada);
    }
  }

  void processarNovoPontoGPS({
    required double latitude,
    required double longitude,
    required double velocidade,
    required DateTime timestamp,
    double? acelerometroMagnitude,
  }) {
    if (tripAtual == null ||
        tripAtual!.status != TripStatus.emAndamento) return;

    final ponto = gpsFilter?.filtrar(
          latitude: latitude,
          longitude: longitude,
          velocidade: velocidade,
          timestamp: timestamp,
          acelerometroMagnitude: acelerometroMagnitude,
        ) ??
        TripPoint(
          latitude: latitude,
          longitude: longitude,
          velocidade: velocidade,
          timestamp: timestamp,
        );

    tripAtual!.adicionarPonto(ponto);
    ultimoPontoProcessado = ponto;

    final service = FlutterBackgroundService();
    service.invoke('updateLocation', {
      'latitude': latitude,
      'longitude': longitude,
      'velocidade': velocidade,
    });
  }

  void _executarCiclo(Timer timer) {
    if (tripAtual == null || tripAtual!.status != TripStatus.emAndamento) {
      return;
    }

    final trip = tripAtual!;
    final ultimo = ultimoPontoProcessado;
    if (ultimo == null) return;

    final veiculoParado =
        ultimo.velocidade < GpsFilter.velocidadeMinimaMovimento;

    if (veiculoParado) {
      trip.tempoParadoSegundos += 1;
      trip.acumuladorTempo += 1;

      final intervalo = trip.fareTable.iTH;
      while (trip.acumuladorTempo >= intervalo) {
        trip.nf += 1;
        trip.acumuladorTempo -= intervalo;
        _onFracaoAtualizada.add(trip.nf);
      }
    } else {
      final pontoAnterior = trip.pontos.length >= 2
          ? trip.pontos[trip.pontos.length - 2]
          : null;

      if (pontoAnterior != null) {
        final distancia = _calcularDistancia(
          pontoAnterior.latitude,
          pontoAnterior.longitude,
          ultimo.latitude,
          ultimo.longitude,
        );

        if (distancia > 0 && distancia < 50) {
          trip.distanciaTotalMetros += distancia;
          trip.acumuladorDistancia += distancia;
        }
      }

      trip.acumuladorTempo = 0;
      trip.tempoMovimentoSegundos += 1;

      final intervalo = trip.tarifaAtiva == 1
          ? trip.fareTable.i1
          : trip.fareTable.i2;

      while (trip.acumuladorDistancia >= intervalo &&
          intervalo > 0) {
        trip.nf += 1;
        trip.acumuladorDistancia -= intervalo;
        _onFracaoAtualizada.add(trip.nf);
      }
    }

    _onValorAtualizado.add(trip.valorTotal);
    _onDistanciaAtualizada.add(trip.distanciaTotalMetros);

    final service = FlutterBackgroundService();
    service.invoke('updateNotification', {
      'title': 'Taxímetro Digital',
      'content':
          'R\$${trip.valorTotal.toStringAsFixed(2)} · ${(trip.distanciaTotalMetros / 1000).toStringAsFixed(2)} km · T${trip.tarifaAtiva}',
    });

    final tempoTotal = Duration(
      seconds:
          (trip.tempoMovimentoSegundos + trip.tempoParadoSegundos).toInt(),
    );
    _onTempoAtualizado.add(tempoTotal);

    _salvarCheckpoint(trip);
  }

  double _calcularDistancia(
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

  void _salvarCheckpoint(Trip trip) {
    if ((trip.tempoMovimentoSegundos + trip.tempoParadoSegundos) % 10 ==
        0) {}
  }

  void dispose() {
    _timer?.cancel();
    _onValorAtualizado.close();
    _onDistanciaAtualizada.close();
    _onTempoAtualizado.close();
    _onStatusChanged.close();
    _onFracaoAtualizada.close();
  }
}
