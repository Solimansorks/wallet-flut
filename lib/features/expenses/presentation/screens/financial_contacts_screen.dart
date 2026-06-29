import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wallet/features/expenses/presentation/controllers/loan_controller.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';

class FinancialContactsScreen extends ConsumerWidget {
  const FinancialContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = ref.watch(l10nProvider);
    final contacts = ref.watch(contactProfilesProvider);
    final loans = ref.watch(loanControllerProvider).loans;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('financial_contacts'))),
      body: SafeArea(
        child: contacts.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    l10n.locale.languageCode == 'ar' ? 'لا يوجد جهات اتصال مالية مسجلة' : 'No financial contacts recorded',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final isOwed = contact.netBalance >= 0;
                  final displayBal = contact.netBalance.abs();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          contact.name.characters.first.toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ),
                      title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.locale.languageCode == 'ar'
                                  ? 'عدد الديون النشطة: ${contact.activeLoansCount}'
                                  : 'Active Loans: ${contact.activeLoansCount}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.locale.languageCode == 'ar'
                                  ? 'آخر تفاعل: ${contact.lastActiveDate}'
                                  : 'Last active: ${contact.lastActiveDate}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isOwed 
                                ? (l10n.locale.languageCode == 'ar' ? 'ليا عنده' : 'Owes Me')
                                : (l10n.locale.languageCode == 'ar' ? 'عليا ليه' : 'I Owe'),
                            style: TextStyle(fontSize: 10, color: isOwed ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${displayBal.toStringAsFixed(0)} ${l10n.translate('currency')}',
                            style: TextStyle(
                              color: isOwed ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Show all loans for this contact in a details bottom sheet dialog
                        final contactLoans = loans.where((l) => l.personName == contact.name).toList();
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                          builder: (ctx) {
                            return SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact.name,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: contactLoans.length,
                                        itemBuilder: (context, idx) {
                                          final l = contactLoans[idx];
                                          final rem = l.totalAmount - l.paidAmount;
                                          return ListTile(
                                            leading: Icon(
                                              l.type == 'lent' ? Icons.arrow_upward : Icons.arrow_downward,
                                              color: l.type == 'lent' ? Colors.green : Colors.red,
                                            ),
                                            title: Text('${l.totalAmount} ${l10n.translate('currency')}'),
                                            subtitle: Text('${l.date} - ${l10n.translate('loan_status_${l.status}')}'),
                                            trailing: Text(
                                              '${rem.toStringAsFixed(0)} ${l10n.translate('currency')}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                                            ),
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              context.push('/loan-details/${l.id}');
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
