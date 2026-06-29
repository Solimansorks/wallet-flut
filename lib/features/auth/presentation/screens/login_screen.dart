import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wallet/features/auth/presentation/controllers/auth_controller.dart';
import 'package:personal_wallet/features/settings/presentation/controllers/settings_controller.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _enteredPin = '';

  void _handleNumberPress(String number) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += number;
      });
      
      // Auto-submit if it reaches 4 digits (or let them press check if we want,
      // but auto-submitting standard 4 digits is extremely slick!)
      if (_enteredPin.length == 4) {
        _submitPin();
      }
    }
  }

  void _handleBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _submitPin() {
    final l10n = ref.read(l10nProvider);
    final success = ref.read(authControllerProvider.notifier).login(
          _enteredPin,
          true, // Auto login
        );

    if (success) {
      context.go('/home');
    } else {
      setState(() {
        _enteredPin = ''; // clear on fail
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('wrong_pin')),
          backgroundColor: Colors.red,
        ),
      );
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
        actions: [
          IconButton(
            icon: Icon(Icons.language_rounded, color: theme.colorScheme.primary),
            onPressed: () => settingsCtrl.toggleLanguage(),
            tooltip: 'Toggle Language',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              l10n.translate('enter_pin'),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            // Pin Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isFilled 
                        ? theme.colorScheme.primary 
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFilled ? theme.colorScheme.primary : Colors.grey.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),
            // Custom Numpad Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.0,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  // Key mapping
                  if (index == 9) {
                    // Empty space or clear button
                    return const SizedBox();
                  }
                  if (index == 10) {
                    // Number 0
                    return _buildNumpadButton('0', theme);
                  }
                  if (index == 11) {
                    // Backspace
                    return IconButton(
                      icon: Icon(Icons.backspace_outlined, size: 28, color: theme.colorScheme.primary),
                      onPressed: _handleBackspace,
                    );
                  }
                  // Numbers 1-9
                  final num = (index + 1).toString();
                  return _buildNumpadButton(num, theme);
                },
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                '© 2026 Developed by Eng.mohamedsoliman',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.withOpacity(0.6),
                  letterSpacing: 0.5,
                  fontSize: 10,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadButton(String number, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return OutlinedButton(
      onPressed: () => _handleNumberPress(number),
      style: OutlinedButton.styleFrom(
        shape: const CircleBorder(),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      ),
      child: Text(
        number,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }
}
