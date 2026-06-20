import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/models/fare_table.dart';

class FareTableCard extends StatelessWidget {
  final FareTable ft;

  const FareTableCard({super.key, required this.ft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text('TABELA TARIFÁRIA · PORTARIA INMETRO Nº 201/2002',
                  style: AppTypography.tableLabel
                      .copyWith(color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniChip('Ba', 'R\$${ft.bandeirada.toStringAsFixed(2)}'),
              const SizedBox(width: 8),
              _miniChip('f', 'R\$${ft.fracao.toStringAsFixed(2)}'),
              const SizedBox(width: 8),
              _miniChip('TH', 'R\$${ft.tarifaHoraria.toStringAsFixed(2)}/h'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _miniChip('i1', '${ft.i1.toStringAsFixed(2)} m',
                  color: AppColors.tariff1),
              const SizedBox(width: 8),
              _miniChip('i2', '${ft.i2.toStringAsFixed(2)} m',
                  color: AppColors.tariff2),
              const SizedBox(width: 8),
              _miniChip('iTH', '${ft.iTH.toStringAsFixed(1)} s',
                  color: AppColors.statusGold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: color?.withValues(alpha: 0.3) ?? AppColors.divider),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTypography.tableValue.copyWith(
                  color: color ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                )),
            Text(label,
                style: AppTypography.tableLabel
                    .copyWith(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
