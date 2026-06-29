import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wallet/features/auth/presentation/screens/splash_screen.dart';
import 'package:personal_wallet/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_wallet/features/auth/presentation/screens/pin_setup_screen.dart';
import 'package:personal_wallet/features/home/presentation/screens/home_screen.dart';
import 'package:personal_wallet/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:personal_wallet/features/expenses/presentation/screens/expense_details_screen.dart';
import 'package:personal_wallet/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:personal_wallet/features/settings/presentation/screens/settings_screen.dart';
import 'package:personal_wallet/features/expenses/presentation/screens/loans_screen.dart';
import 'package:personal_wallet/features/expenses/presentation/screens/add_loan_screen.dart';
import 'package:personal_wallet/features/expenses/presentation/screens/loan_details_screen.dart';
import 'package:personal_wallet/features/expenses/presentation/screens/financial_contacts_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/pin-setup',
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) {
          final idString = state.uri.queryParameters['id'];
          final id = idString != null ? int.tryParse(idString) : null;
          return AddExpenseScreen(expenseId: id);
        },
      ),
      GoRoute(
        path: '/transaction-details/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ExpenseDetailsScreen(expenseId: id);
        },
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/loans',
        builder: (context, state) => const LoansScreen(),
      ),
      GoRoute(
        path: '/add-loan',
        builder: (context, state) => const AddLoanScreen(),
      ),
      GoRoute(
        path: '/loan-details/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return LoanDetailsScreen(loanId: id);
        },
      ),
      GoRoute(
        path: '/financial-contacts',
        builder: (context, state) => const FinancialContactsScreen(),
      ),
    ],
  );
});
