import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wallet/core/services/service_providers.dart';
import 'package:personal_wallet/features/settings/presentation/controllers/settings_controller.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';
import 'package:personal_wallet/shared/widgets/custom_button.dart';
import 'package:personal_wallet/shared/widgets/custom_text_field.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _balanceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _saveSetup() async {
    if (_formKey.currentState?.validate() ?? false) {
      final storage = ref.read(storageServiceProvider);
      final pin = _pinController.text;
      final initialBalance = double.tryParse(_balanceController.text) ?? 0.0;

      await storage.setPin(pin);
      await storage.setInitialBalance(initialBalance);

      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(l10nProvider);
    final settingsCtrl = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('pin_setup_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded),
            onPressed: () => settingsCtrl.toggleLanguage(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  l10n.translate('pin_setup_title'),
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.locale.languageCode == 'ar'
                      ? 'يرجى تعيين رمز PIN لحماية محفظتك وتحديد رصيدك الافتتاحي.'
                      : 'Please set up a PIN code to protect your wallet and set your initial balance.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),

                // PIN Field
                CustomTextField(
                  controller: _pinController,
                  labelText: l10n.translate('pin'),
                  hintText: '1234',
                  isPassword: true,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.translate('pin_required');
                    }
                    if (value.length < 4 || value.length > 6) {
                      return l10n.locale.languageCode == 'ar'
                          ? 'يجب أن يتكون رمز الـ PIN من 4 إلى 6 أرقام'
                          : 'PIN must be 4 to 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm PIN Field
                CustomTextField(
                  controller: _confirmPinController,
                  labelText: l10n.translate('confirm_pin'),
                  hintText: '1234',
                  isPassword: true,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (value) {
                    if (value != _pinController.text) {
                      return l10n.translate('pin_mismatch');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Initial Balance Field
                CustomTextField(
                  controller: _balanceController,
                  labelText: l10n.translate('initial_balance'),
                  hintText: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final val = double.tryParse(value);
                      if (val == null || val < 0) {
                        return l10n.translate('invalid_amount');
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                CustomButton(
                  text: l10n.translate('save_setup'),
                  onPressed: _saveSetup,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
