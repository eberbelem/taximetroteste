class FareTable {
  final double bandeirada; // Ba (R$)
  final double fracao; // f (R$) — valor de cada fração
  final double tarifa1; // B1 (R$/km)
  final double tarifa2; // B2 (R$/km)
  final double tarifaHoraria; // TH (R$/h)

  const FareTable({
    required this.bandeirada,
    required this.fracao,
    required this.tarifa1,
    required this.tarifa2,
    required this.tarifaHoraria,
  });

  double get i1 => (fracao * 1000.0) / tarifa1;
  double get i2 => (fracao * 1000.0) / tarifa2;
  double get iTH => (fracao * 3600.0) / tarifaHoraria;

  double get intervalo1 => i1;
  double get intervalo2 => i2;
  double get intervaloTH => iTH;

  factory FareTable.padrao() => const FareTable(
        bandeirada: 6.76,
        fracao: 0.35,
        tarifa1: 3.43,
        tarifa2: 4.12,
        tarifaHoraria: 31.19,
      );

  Map<String, dynamic> toMap() => {
        'bandeirada': bandeirada,
        'fracao': fracao,
        'tarifa1': tarifa1,
        'tarifa2': tarifa2,
        'tarifaHoraria': tarifaHoraria,
      };

  factory FareTable.fromMap(Map<String, dynamic> map) => FareTable(
        bandeirada: (map['bandeirada'] as num).toDouble(),
        fracao: (map['fracao'] as num).toDouble(),
        tarifa1: (map['tarifa1'] as num).toDouble(),
        tarifa2: (map['tarifa2'] as num).toDouble(),
        tarifaHoraria: (map['tarifaHoraria'] as num).toDouble(),
      );
}
