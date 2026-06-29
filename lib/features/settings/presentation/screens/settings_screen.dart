import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wallet/core/services/export_service.dart';
import 'package:personal_wallet/core/services/service_providers.dart';
import 'package:personal_wallet/features/auth/presentation/controllers/auth_controller.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:personal_wallet/features/expenses/domain/models/transaction.dart';
import 'package:personal_wallet/features/settings/presentation/controllers/settings_controller.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';
import 'package:personal_wallet/shared/widgets/custom_text_field.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _showChangePinDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.translate('change_password')),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _pinController,
                  labelText: l10n.translate('new_password'),
                  hintText: '1234',
                  isPassword: true,
                  keyboardType: TextInputType.number,
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
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPinController,
                  labelText: l10n.translate('confirm_password'),
                  hintText: '1234',
                  isPassword: true,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != _pinController.text) {
                      return l10n.translate('passwords_dont_match');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final auth = ref.read(authControllerProvider.notifier);
                  await auth.changePassword(_pinController.text);
                  
                  _pinController.clear();
                  _confirmPinController.clear();
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.translate('password_changed_success')),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.translate('save')),
            ),
          ],
        );
      },
    );
  }

  void _exportCSV(List<Transaction> txs, AppLocalizations l10n) async {
    try {
      await ExportService.exportToCSV(txs, l10n);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('export_success')), backgroundColor: Colors.green),
        );
      }
    } catch (_) {}
  }

  void _exportExcel(List<Transaction> txs, AppLocalizations l10n) async {
    try {
      await ExportService.exportToExcel(txs, l10n);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('export_success')), backgroundColor: Colors.green),
        );
      }
    } catch (_) {}
  }

  void _exportPDF(List<Transaction> txs, AppLocalizations l10n) async {
    try {
      await ExportService.exportToPDF(txs, l10n);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('export_success')), backgroundColor: Colors.green),
        );
      }
    } catch (_) {}
  }

  void _createBackup(List<Transaction> txs, AppLocalizations l10n) async {
    try {
      final storage = ref.read(storageServiceProvider);
      final initialBalance = storage.getInitialBalance();

      final List<Map<String, dynamic>> txListJson = txs.map((t) => {
        'id': t.id,
        'amount': t.amount,
        'type': t.type,
        'category': t.category,
        'description': t.description,
        'date': t.date,
        'time': t.time,
        'createdAt': t.createdAt.toIso8601String(),
        'updatedAt': t.updatedAt.toIso8601String(),
      }).toList();

      final Map<String, dynamic> backupJson = {
        'transactions': txListJson,
        'initialBalance': initialBalance,
        'backupVersion': 1,
      };

      final jsonString = jsonEncode(backupJson);
      final dir = await getTemporaryDirectory();
      
      final now = DateTime.now();
      final dateStr = "${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}";
      final file = File('${dir.path}/wallet_backup_$dateStr.json');
      await file.writeAsString(jsonString);

      final xfile = XFile(file.path);
      await Share.shareXFiles([xfile], subject: 'Personal Wallet Backup');
    } catch (_) {}
  }

  void _backupAndWipeData(List<Transaction> txs, AppLocalizations l10n) async {
    try {
      final storage = ref.read(storageServiceProvider);
      final initialBalance = storage.getInitialBalance();

      final List<Map<String, dynamic>> txListJson = txs.map((t) => {
        'id': t.id,
        'amount': t.amount,
        'type': t.type,
        'category': t.category,
        'description': t.description,
        'date': t.date,
        'time': t.time,
        'createdAt': t.createdAt.toIso8601String(),
        'updatedAt': t.updatedAt.toIso8601String(),
      }).toList();

      final Map<String, dynamic> backupJson = {
        'transactions': txListJson,
        'initialBalance': initialBalance,
        'backupVersion': 1,
      };

      final jsonString = jsonEncode(backupJson);
      final dir = await getTemporaryDirectory();
      
      final now = DateTime.now();
      final dateStr = "${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}";
      final file = File('${dir.path}/wallet_backup_$dateStr.json');
      await file.writeAsString(jsonString);

      final xfile = XFile(file.path);
      await Share.shareXFiles([xfile], subject: 'Personal Wallet Backup');

      // Show confirmation dialog to Wipe Data
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _confirmWipeData(l10n);
        }
      });
    } catch (_) {}
  }

  void _restoreBackup(AppLocalizations l10n) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      
      final Map<String, dynamic> backupData = jsonDecode(content);
      
      if (!backupData.containsKey('transactions')) {
        throw const FormatException('Invalid backup file structure');
      }

      final List<dynamic> transactionsJson = backupData['transactions'] ?? [];
      final double initialBalance = (backupData['initialBalance'] as num?)?.toDouble() ?? 0.0;

      final List<Transaction> loadedTransactions = [];
      for (var json in transactionsJson) {
        final tx = Transaction()
          ..id = json['id'] ?? 0
          ..amount = (json['amount'] as num).toDouble()
          ..type = json['type'] ?? 'expense'
          ..category = json['category'] ?? 'Other'
          ..description = json['description'] ?? ''
          ..date = json['date'] ?? ''
          ..time = json['time'] ?? ''
          ..createdAt = DateTime.parse(json['createdAt'])
          ..updatedAt = DateTime.parse(json['updatedAt']);
        loadedTransactions.add(tx);
      }

      final storage = ref.read(storageServiceProvider);
      await storage.setInitialBalance(initialBalance);
      await ref.read(expenseControllerProvider.notifier).importBackup(loadedTransactions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('import_success')), backgroundColor: Colors.green),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('import_failed')), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmWipeData(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.translate('delete_all_data')),
          content: Text(l10n.translate('wipe_confirm_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            TextButton(
              onPressed: () async {
                final storage = ref.read(storageServiceProvider);
                await storage.clearAll();
                await ref.read(expenseControllerProvider.notifier).wipeAllData();
                
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/splash');
                }
              },
              child: Text(
                l10n.translate('yes'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = ref.watch(l10nProvider);
    final settings = ref.watch(settingsControllerProvider);
    final settingsCtrl = ref.read(settingsControllerProvider.notifier);
    final txs = ref.watch(expenseControllerProvider).transactions;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App Settings Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.translate('dark_mode')),
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (val) => settingsCtrl.toggleTheme(val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l10n.locale.languageCode == 'ar' ? 'اللغة (English)' : 'Language (العربية)'),
                    trailing: const Icon(Icons.translate_rounded),
                    onTap: () => settingsCtrl.toggleLanguage(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l10n.translate('change_password')),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () => _showChangePinDialog(l10n),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Export Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      l10n.translate('export_data'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                    title: const Text('PDF Document'),
                    onTap: () => _exportPDF(txs, l10n),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.grid_on_outlined, color: Colors.green),
                    title: const Text('Excel Spreadsheet'),
                    onTap: () => _exportExcel(txs, l10n),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.article_outlined, color: Colors.blue),
                    title: const Text('CSV Format'),
                    onTap: () => _exportCSV(txs, l10n),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Backup & Wipe Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.backup_outlined, color: Colors.teal),
                    title: Text(l10n.locale.languageCode == 'ar' ? 'إنشاء نسخة احتياطية (JSON)' : 'Create Backup (JSON)'),
                    onTap: () => _createBackup(txs, l10n),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore_outlined, color: Colors.indigo),
                    title: Text(l10n.translate('import_data')),
                    onTap: () => _restoreBackup(l10n),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.swap_horizontal_circle_outlined, color: Colors.amber),
                    title: Text(l10n.translate('backup_and_wipe')),
                    onTap: () => _backupAndWipeData(txs, l10n),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                    title: Text(l10n.translate('delete_all_data'), style: const TextStyle(color: Colors.red)),
                    onTap: () => _confirmWipeData(l10n),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // About block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(
                  l10n.translate('about'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.translate('about_text'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  '© 2026 Developed by Eng.mohamedsoliman',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
