import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class FareDisplay extends StatelessWidget {
  final double valor;
  final bool isRunning;
  final bool showTotalLabel;

  const FareDisplay({
    super.key,
    required this.valor,
    this.isRunning = false,
    this.showTotalLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final inteiro = valor.toStringAsFixed(2).split('.')[0];
    final centavos = valor.toStringAsFixed(2).split('.')[1];
    final screenHeight = MediaQuery.of(context).size.height;

    Color cor;
    if (showTotalLabel) {
      cor = AppColors.farePrimary;
    } else if (isRunning) {
      cor = AppColors.farePrimary;
    } else {
      cor = AppColors.textTertiary;
    }

    final fontSize = (screenHeight * 0.12).clamp(48.0, 96.0);
    final currencySize = fontSize * 0.28;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTotalLabel)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.farePrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.farePrimary.withValues(alpha: 0.3)),
            ),
            child: Text(
              'TOTAL A PAGAR',
              style: TextStyle(
                fontSize: (screenHeight * 0.018).clamp(11.0, 13.0),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.farePrimary,
              ),
            ),
          ),
        SizedBox(
          height: fontSize * 1.2,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: currencySize * 0.5),
                  child: Text(
                    'R\$',
                    style: TextStyle(
                      fontSize: currencySize,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.0,
                      color: cor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  inteiro,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 3.0,
                    color: cor,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: currencySize * 0.5),
                  child: Text(
                    ',$centavos',
                    style: TextStyle(
                      fontSize: currencySize,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.0,
                      color: cor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 3,
          width: showTotalLabel || isRunning ? 240 : 120,
          decoration: BoxDecoration(
            color: showTotalLabel || isRunning
                ? AppColors.farePrimary
                : AppColors.textDim,
            borderRadius: BorderRadius.circular(2),
            boxShadow: showTotalLabel || isRunning
                ? [
                    BoxShadow(
                      color: AppColors.farePrimary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}
