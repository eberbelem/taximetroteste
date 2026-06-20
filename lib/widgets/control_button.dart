import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ControlButton extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onPressed;

  const ControlButton({
    super.key,
    required this.isRunning,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cor = isRunning ? AppColors.stopRed : AppColors.startGreen;
    final icono = isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded;
    final rotulo = isRunning ? 'ENCERRAR CORRIDA' : 'INICIAR CORRIDA';

    return SizedBox(
      width: double.infinity,
      height: 68,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: cor.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: cor,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icono, size: 32, color: AppColors.background),
                  const SizedBox(width: 16),
                  Text(
                    rotulo,
                    style: AppTypography.buttonLabel
                        .copyWith(color: AppColors.background),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
