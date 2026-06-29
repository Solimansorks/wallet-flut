# Tasks - Loans, Debts & Transaction Engine

- [x] Create Loan collection schema under `lib/features/expenses/domain/models/loan.dart`
- [x] Expand Transaction model fields (`toWalletId`, `loanId`)
- [x] Run `build_runner` to generate all Isar collection schemas
- [x] Round schema big integers in generated files for Web previews
- [x] Update `database_service.dart` with unified wallet calculations and Loan CRUD mock operations
- [x] Update `statistics_controller.dart` for loans math, dynamic contacts profiling, and trends
- [x] Add localization translations in `app_localizations.dart` for loans, debts, and contacts
- [x] Create UI Screens:
  - [x] `add_loan_screen.dart` (input sheet for lending/borrowing money)
  - [x] `loan_details_screen.dart` (progress bars, partial payments sheet, logs)
  - [x] `loans_screen.dart` (overview dashboard, toggles, filter chips)
  - [x] `financial_contacts_screen.dart` (contact sheets and profile history)
- [x] Set up routes in `app_router.dart`
- [x] Run compiler check and verify unit tests
