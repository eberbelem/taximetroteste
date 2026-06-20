import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class TariffSelector extends StatelessWidget {
  final int tarifaAtiva;
  final double tarifa1;
  final double tarifa2;
  final VoidCallback? onTarifa1;
  final VoidCallback? onTarifa2;

  const TariffSelector({
    super.key,
    required this.tarifaAtiva,
    required this.tarifa1,
    required this.tarifa2,
    this.onTarifa1,
    this.onTarifa2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'BANDEIRA ATIVA',
          style: AppTypography.tabHeader.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _TariffCard(
              label: 'BANDEIRA 1',
              value: tarifa1,
              cor: AppColors.tariff1,
              selected: tarifaAtiva == 1,
              onTap: onTarifa1,
            ),
            const SizedBox(width: 12),
            _TariffCard(
              label: 'BANDEIRA 2',
              value: tarifa2,
              cor: AppColors.tariff2,
              selected: tarifaAtiva == 2,
              onTap: onTarifa2,
            ),
          ],
        ),
      ],
    );
  }
}

class _TariffCard extends StatelessWidget {
  final String label;
  final double value;
  final Color cor;
  final bool selected;
  final VoidCallback? onTap;

  const _TariffCard({
    required this.label,
    required this.value,
    required this.cor,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? cor.withValues(alpha: 0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? cor : AppColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTypography.tariffLabel.copyWith(
                  color: selected ? cor : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'R\$${value.toStringAsFixed(2)}/km',
                style: AppTypography.tariffSub.copyWith(
                  color: selected
                      ? cor.withValues(alpha: 0.7)
                      : AppColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
