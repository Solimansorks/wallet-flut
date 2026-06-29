import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';

void main() {
  test('Localization Dictionary Test', () {
    final arL10n = AppLocalizations(const Locale('ar'));
    final enL10n = AppLocalizations(const Locale('en'));

    expect(arL10n.translate('app_name'), 'وفير');
    expect(enL10n.translate('app_name'), 'Wafeer');
    
    expect(arL10n.getCategoryTranslation('Food'), 'طعام');
    expect(enL10n.getCategoryTranslation('Food'), 'Food');
  });
}
