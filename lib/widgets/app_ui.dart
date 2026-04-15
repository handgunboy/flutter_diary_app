import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppUi {
  const AppUi._();

  static const EdgeInsets pagePadding = EdgeInsets.all(16);
  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(10, 12, 10, 12);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const double sectionGap = 16;
  static const double itemGap = 12;
  static const Duration fastDuration = Duration(milliseconds: 180);
  static const Duration baseDuration = Duration(milliseconds: 220);
  static const Duration shortDebounce = Duration(milliseconds: 300);
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(8));

  static Color subtleSurface(BuildContext context) {
    return AppColors.of(context).surfaceSubtle;
  }

  static Color secondaryFabBackground(BuildContext context) {
    return AppColors.of(context).calendarControlBackground;
  }

  static Color secondaryFabForeground(BuildContext context) {
    return AppColors.of(context).textPrimary;
  }

  static Color mutedText(BuildContext context) {
    return AppColors.of(context).textMuted;
  }

  static Color mutedIcon(BuildContext context) {
    return AppColors.of(context).iconMuted;
  }
}
