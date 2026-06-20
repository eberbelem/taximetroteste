import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class InfoPanel extends StatelessWidget {
  final String tempo;
  final double distanciaKm;
  final int fracoes;

  const InfoPanel({
    super.key,
    required this.tempo,
    required this.distanciaKm,
    required this.fracoes,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final vPad = (screenHeight * 0.02).clamp(10.0, 16.0);
    final fontSize = (screenHeight * 0.03).clamp(16.0, 22.0);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: vPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _InfoTile(label: 'TEMPO', value: tempo)),
          _divider(),
          Expanded(
              child: _InfoTile(
                  label: 'DISTÂNCIA',
                  value: '${distanciaKm.toStringAsFixed(2)} km')),
          _divider(),
          Expanded(
              child: _InfoTile(
                  label: 'FRAÇÕES', value: fracoes.toString())),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.divider,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    final vs = (sh * 0.03).clamp(16.0, 22.0);
    final ls = (sh * 0.017).clamp(11.0, 13.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: vs,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: ls,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
