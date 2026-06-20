import 'dart:convert';

enum TripStatus { aguardando, emAndamento, encerrada }

class TripPoint {
  final double latitude;
  final double longitude;
  final double velocidade;
  final DateTime timestamp;

  const TripPoint({
    required this.latitude,
    required this.longitude,
    required this.velocidade,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'velocidade': velocidade,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TripPoint.fromMap(Map<String, dynamic> map) => TripPoint(
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        velocidade: (map['velocidade'] as num).toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}

class Trip {
  final String id;
  final FareTable fareTable;
  final DateTime inicio;
  DateTime? fim;
  TripStatus status;
  final List<TripPoint> pontos;

  int nf;
  double acumuladorDistancia;
  double acumuladorTempo;
  double distanciaTotalMetros;
  double tempoParadoSegundos;
  double tempoMovimentoSegundos;
  int tarifaAtiva;

  Trip({
    required this.id,
    required this.fareTable,
    required this.inicio,
    this.fim,
    this.status = TripStatus.aguardando,
    List<TripPoint>? pontos,
    this.nf = 1,
    this.acumuladorDistancia = 0.0,
    this.acumuladorTempo = 0.0,
    this.distanciaTotalMetros = 0.0,
    this.tempoParadoSegundos = 0.0,
    this.tempoMovimentoSegundos = 0.0,
    this.tarifaAtiva = 1,
  }) : pontos = pontos ?? [];

  double get valorTotal => fareTable.bandeirada + (nf * fareTable.fracao);

  void adicionarPonto(TripPoint ponto) {
    pontos.add(ponto);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'fareTable': jsonEncode(fareTable.toMap()),
        'inicio': inicio.toIso8601String(),
        'fim': fim?.toIso8601String(),
        'status': status.index,
        'nf': nf,
        'acumuladorDistancia': acumuladorDistancia,
        'acumuladorTempo': acumuladorTempo,
        'distanciaTotalMetros': distanciaTotalMetros,
        'tempoParadoSegundos': tempoParadoSegundos,
        'tempoMovimentoSegundos': tempoMovimentoSegundos,
        'tarifaAtiva': tarifaAtiva,
        'pontos': jsonEncode(pontos.map((p) => p.toMap()).toList()),
      };

  factory Trip.fromMap(Map<String, dynamic> map) => Trip(
        id: map['id'] as String,
        fareTable:
            FareTable.fromMap(jsonDecode(map['fareTable'] as String)),
        inicio: DateTime.parse(map['inicio'] as String),
        fim: map['fim'] != null
            ? DateTime.parse(map['fim'] as String)
            : null,
        status: TripStatus.values[map['status'] as int],
        nf: (map['nf'] as num?)?.toInt() ?? 1,
        acumuladorDistancia:
            (map['acumuladorDistancia'] as num?)?.toDouble() ?? 0.0,
        acumuladorTempo:
            (map['acumuladorTempo'] as num?)?.toDouble() ?? 0.0,
        distanciaTotalMetros:
            (map['distanciaTotalMetros'] as num?)?.toDouble() ?? 0.0,
        tempoParadoSegundos:
            (map['tempoParadoSegundos'] as num?)?.toDouble() ?? 0.0,
        tempoMovimentoSegundos:
            (map['tempoMovimentoSegundos'] as num?)?.toDouble() ?? 0.0,
        tarifaAtiva: (map['tarifaAtiva'] as num?)?.toInt() ?? 1,
        pontos: (jsonDecode(map['pontos'] as String) as List)
            .map((p) => TripPoint.fromMap(p as Map<String, dynamic>))
            .toList(),
      );

  String formatarValor() => 'R\$ ${valorTotal.toStringAsFixed(2)}';
}
