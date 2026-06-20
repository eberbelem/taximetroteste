import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D0D);
  static const Color surfaceLight = Color(0xFF1A1A1A);
  static const Color card = Color(0xFF111111);
  static const Color cardBorder = Color(0xFF1F1F1F);

  static const Color farePrimary = Color(0xFF39FF14);
  static const Color farePrimaryDim = Color(0xFF2BBF0F);
  static const Color fareSecondary = Color(0xFF00F0FF);

  static const Color statusGold = Color(0xFFFFD700);
  static const Color statusOrange = Color(0xFFFF5722);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF707070);
  static const Color textDim = Color(0xFF404040);

  static const Color tariff1 = Color(0xFF39FF14);
  static const Color tariff2 = Color(0xFF00F0FF);

  static const Color stopRed = Color(0xFFFF1744);
  static const Color startGreen = Color(0xFF00E676);

  static const Color divider = Color(0xFF1F1F1F);
  static const Color dimOverlay = Color(0x40FFFFFF);

  static const Color fractionBadge = Color(0xFFFFD700);
  static const Color fractionBadgeBg = Color(0x1AFFD700);
}

class AppTypography {
  AppTypography._();

  static const _font = '';

  static const TextStyle fareValue = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w200,
    letterSpacing: 2.0,
    height: 1.0,
  );

  static const TextStyle fareValueLarge = TextStyle(
    fontSize: 96,
    fontWeight: FontWeight.w200,
    letterSpacing: 3.0,
    height: 1.0,
  );

  static const TextStyle fareCurrency = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    letterSpacing: 1.0,
    height: 1.0,
  );

  static const TextStyle timer = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w300,
    letterSpacing: 2.0,
    height: 1.0,
  );

  static const TextStyle infoValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle infoLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    height: 1.2,
  );

  static const TextStyle fractionNumber = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w300,
    letterSpacing: 1.0,
    height: 1.0,
  );

  static const TextStyle fractionLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    height: 1.2,
  );

  static const TextStyle tariffLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle tariffSub = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.2,
  );

  static const TextStyle tabHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    height: 1.2,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    height: 1.2,
  );

  static const TextStyle tableValue = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.4,
  );

  static const TextStyle tableLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.4,
  );

  static const TextStyle notificationContent = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.4,
    color: AppColors.textSecondary,
  );
}
