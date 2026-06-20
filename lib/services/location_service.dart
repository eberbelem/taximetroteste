import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/models/trip.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double? _ultimaMagnitudeAcelerometro;

  StreamController<TripPoint>? _locationController;
  Stream<TripPoint>? locationStream;

  static const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
    timeLimit: null,
  );

  Future<bool> solicitarPermissoes() async {
    final location = await [
      Permission.location,
      Permission.locationAlways,
      Permission.activityRecognition,
      Permission.ignoreBatteryOptimizations,
    ].request();

    return location[Permission.location] == PermissionStatus.granted &&
        location[Permission.locationAlways] == PermissionStatus.granted;
  }

  Future<void> iniciarMonitoramento() async {
    _locationController = StreamController<TripPoint>.broadcast();
    locationStream = _locationController!.stream;

    final permissoes = await solicitarPermissoes();
    if (!permissoes) {
      throw Exception('Permissões de localização não concedidas');
    }

    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen((event) {
      _ultimaMagnitudeAcelerometro = _calcularMagnitude(event);
    });

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final ponto = TripPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        velocidade: position.speed,
        timestamp: position.timestamp ?? DateTime.now(),
      );
      _locationController!.add(ponto);
    });
  }

  double? get magnitudeAcelerometro => _ultimaMagnitudeAcelerometro;

  double _calcularMagnitude(AccelerometerEvent event) {
    return (event.x * event.x + event.y * event.y + event.z * event.z);
  }

  Future<bool> isGpsHabilitado() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  void pararMonitoramento() {
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _locationController?.close();
    _locationController = null;
    locationStream = null;
  }
}
