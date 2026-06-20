import 'package:flutter_test/flutter_test.dart';
import '../lib/core/models/fare_table.dart';

void main() {
  group('FareTable - Planilha Inmetro', () {
    final ft = FareTable(
      bandeirada: 6.76,
      fracao: 0.35,
      tarifa1: 3.43,
      tarifa2: 4.12,
      tarifaHoraria: 31.19,
    );

    test('i1 = (f * 1000) / B1', () {
      final esperado = (0.35 * 1000) / 3.43;
      expect(ft.i1, closeTo(esperado, 0.01));
      expect(ft.i1, closeTo(102.04, 0.01));
    });

    test('i2 = (f * 1000) / B2', () {
      final esperado = (0.35 * 1000) / 4.12;
      expect(ft.i2, closeTo(esperado, 0.01));
      expect(ft.i2, closeTo(84.95, 0.01));
    });

    test('iTH = (f * 3600) / TH', () {
      final esperado = (0.35 * 3600) / 31.19;
      expect(ft.iTH, closeTo(esperado, 0.1));
      expect(ft.iTH, closeTo(40.4, 0.1));
    });

    test('Bandeira 1: n = ceil(1000 / i1) = 10', () {
      final n = (1000.0 / ft.i1).ceil();
      expect(n, 10);
      final dnf = n * ft.i1;
      expect(dnf, closeTo(1020.4, 0.1));
      final indicacao = ft.bandeirada + n * ft.fracao;
      expect(indicacao, closeTo(10.26, 0.01));
    });

    test('Bandeira 2: n = ceil(1000 / i2) = 12', () {
      final n = (1000.0 / ft.i2).ceil();
      expect(n, 12);
      final dnf = n * ft.i2;
      expect(dnf, closeTo(1019.4, 0.1));
      final indicacao = ft.bandeirada + n * ft.fracao;
      expect(indicacao, closeTo(10.96, 0.01));
    });

    test('T3 = (3 * f * 3600) / TH = 121s', () {
      final t3 = (3 * ft.fracao * 3600) / ft.tarifaHoraria;
      expect(t3, closeTo(121.2, 0.5));
    });
  });
}
