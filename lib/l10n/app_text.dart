import 'package:flutter/material.dart';

import 'app_strings.dart';

extension AppTextX on BuildContext {
  AppStrings get appText {
    final code = Localizations.localeOf(this).languageCode.toLowerCase();
    final isSpanish = code.startsWith('es');
    return AppStrings(isSpanish: isSpanish);
  }
}
