import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wallet/features/settings/presentation/controllers/settings_controller.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Wafeer',
      'login': 'PIN Verification',
      'pin': 'PIN Code',
      'pin_required': 'PIN code is required',
      'wrong_pin': 'Incorrect PIN code',
      'enter_pin': 'Enter PIN',
      'confirm_pin': 'Confirm PIN',
      'pin_mismatch': 'PIN codes do not match',
      'pin_setup_title': 'Setup PIN Lock',
      'initial_balance_title': 'Initial Balance',
      'initial_balance': 'Initial Balance',
      'enter_initial_balance': 'Enter your initial wallet balance',
      'save_setup': 'Complete Setup',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'this_year': 'This Year',
      'last_7_days': 'Last 7 Days',
      'custom_range': 'Custom Date Range',
      'recent_expenses': 'Recent Transactions',
      'add_transaction': 'Add Transaction',
      'edit_transaction': 'Edit Transaction',
      'amount': 'Amount',
      'category': 'Category',
      'description': 'Description',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'settings': 'Settings',
      'statistics': 'Statistics',
      'total_expenses': 'Total Expenses',
      'dashboard': 'Dashboard',
      'current_balance': 'Current Balance',
      'total_deposits': 'Total Deposits',
      'today_spent': 'Today Spent',
      'month_spent': 'Month Spent',
      'overall_total': 'Overall Total',
      'total_transactions': 'Total Transactions',
      'highest_expense': 'Highest Expense',
      'lowest_expense': 'Lowest Expense',
      'average_expense': 'Average Expense',
      'no_expenses': 'No transactions recorded yet',
      'no_description': 'No description',
      'search_placeholder': 'Search by amount, category, description...',
      'invalid_amount': 'Amount must be a number greater than 0',
      'description_too_long': 'Description cannot exceed 300 characters',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'change_password': 'Change PIN Code',
      'export_data': 'Export Data',
      'import_data': 'Import Backup',
      'delete_all_data': 'Wipe Wallet Data',
      'about': 'About',
      'about_text': 'Personal Wallet v1.0.0\nA modern, clean, and fast offline money manager built with Flutter and Isar.',
      'new_password': 'New PIN Code',
      'confirm_password': 'Confirm New PIN',
      'passwords_dont_match': 'PIN codes do not match',
      'password_changed_success': 'PIN code changed successfully',
      'delete_confirm_title': 'Are you sure?',
      'delete_confirm_desc': 'This will permanently delete this transaction.',
      'wipe_confirm_desc': 'This will permanently delete all your transactions, settings, and wallet configuration. This action is irreversible.',
      'yes': 'Yes',
      'no': 'No',
      'export_success': 'Report exported successfully',
      'import_success': 'Wallet data restored successfully',
      'import_failed': 'Failed to restore: invalid format',
      'fast_entry': 'Fast Entry',
      'shortcuts': 'Quick Amounts',
      'last_category': 'Last Used',
      'sorting': 'Sort By',
      'sort_newest': 'Newest first',
      'sort_oldest': 'Oldest first',
      'sort_highest': 'Highest amount',
      'sort_lowest': 'Lowest amount',
      'sort_category': 'Category',
      'currency': 'EGP',
      'type': 'Type',
      'deposit': 'Deposit',
      'expense': 'Expense',
      // Advanced features keys
      'loans_debts': 'Loans & Debts',
      'money_lent': 'Money Lent',
      'money_borrowed': 'Money Borrowed',
      'repayment': 'Repayment',
      'financial_contacts': 'Financial Contacts',
      'remaining': 'Remaining',
      'repay_loan': 'Register Repayment',
      'lent_amount': 'Owed to Me',
      'borrowed_amount': 'My Debts',
      'due_date': 'Due Date',
      'loan_status_open': 'Open',
      'loan_status_partial': 'Partial',
      'loan_status_paid': 'Fully Paid',
      'my_debts': 'My Debts',
      'my_loans': 'Owed to Me',
      'active_loans': 'Active Loans',
      'archived_loans': 'Archived',
      'payment_method': 'Payment Method',
      'notes': 'Notes',
      'location': 'Location',
      'hide_balances': 'Hide Balances',
      'budget_limit': 'Budget Ceiling',
      'savings_goals': 'Savings Targets',
      'target': 'Target',
      'saved': 'Saved',
      'quick_add': 'Quick Favorites',
      'payment_cash': 'Cash',
      'payment_visa': 'Visa Card',
      'payment_bank': 'Bank Transfer',
      'payment_instapay': 'Instapay',
      'payment_vodafone': 'Vodafone Cash',
      'payment_ewallet': 'E-Wallet',
      'wallet_name': 'Funding Wallet',
      'new_wallet': 'New Wallet',
      'add_wallet': 'Add Wallet',
      'net_worth': 'Net Worth',
      'budgets': 'Budgets',
      'active_budgets': 'Active Budgets',
      'add_budget': 'Add Budget Limit',
      'add_goal': 'Add Savings Goal',
      'largest_expense': 'Largest Cost',
      'largest_deposit': 'Largest Deposit',
      'daily_avg': 'Daily Avg Cost',
      'comparison_last_month': 'vs Last Month',
      'receipt_photo': 'Receipt Attachment',
      'add_photo': 'Attach Photo',
      'no_photo': 'No Attachment',
      'spent_warning': 'Warning: You consumed 80% of your budget!',
      // Predefined Categories
      'cat_salary': 'Salary',
      'cat_investment': 'Investment',
      'cat_gift': 'Gift',
      'cat_food': 'Food',
      'cat_transport': 'Transport',
      'cat_shopping': 'Shopping',
      'cat_bills': 'Bills',
      'cat_entertainment': 'Entertainment',
      'cat_health': 'Health',
      'cat_education': 'Education',
      'cat_other': 'Other',
    },
    'ar': {
      'app_name': 'وفير',
      'login': 'تأكيد الرمز السري',
      'pin': 'الرمز السري PIN',
      'pin_required': 'رمز الـ PIN مطلوب',
      'wrong_pin': 'رمز الـ PIN غير صحيح',
      'enter_pin': 'أدخل رمز الـ PIN',
      'confirm_pin': 'تأكيد رمز الـ PIN',
      'pin_mismatch': 'رموز الـ PIN غير متطابقة',
      'pin_setup_title': 'إعداد رمز الـ PIN للأمان',
      'initial_balance_title': 'الرصيد الافتتاحي',
      'initial_balance': 'الرصيد الافتتاحي',
      'enter_initial_balance': 'أدخل الرصيد الافتتاحي لمحفظتك',
      'save_setup': 'إكمال الإعداد',
      'today': 'اليوم',
      'yesterday': 'أمس',
      'this_week': 'هذا الأسبوع',
      'this_month': 'هذا الشهر',
      'this_year': 'هذه السنة',
      'last_7_days': 'آخر 7 أيام',
      'custom_range': 'فترة مخصصة',
      'recent_expenses': 'العمليات الأخيرة',
      'add_transaction': 'إضافة عملية',
      'edit_transaction': 'تعديل العملية',
      'amount': 'المبلغ',
      'category': 'التصنيف',
      'description': 'الوصف',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'edit': 'تعديل',
      'search': 'بحث',
      'settings': 'الإعدادات',
      'statistics': 'الإحصائيات',
      'total_expenses': 'إجمالي المصروفات',
      'dashboard': 'لوحة التحكم',
      'current_balance': 'الرصيد الحالي',
      'total_deposits': 'إجمالي الإيداعات',
      'today_spent': 'مصاريف اليوم',
      'month_spent': 'مصاريف الشهر',
      'overall_total': 'الإجمالي الكلي',
      'total_transactions': 'عدد العمليات',
      'highest_expense': 'أعلى مصروف',
      'lowest_expense': 'أقل مصروف',
      'average_expense': 'متوسط الصرف',
      'no_expenses': 'لم يتم تسجيل أي عمليات بعد',
      'no_description': 'لا يوجد وصف',
      'search_placeholder': 'ابحث بالمبلغ، التصنيف، الوصف...',
      'invalid_amount': 'يجب أن يكون المبلغ رقمًا أكبر من 0',
      'description_too_long': 'لا يمكن للوصف أن يتجاوز 300 حرف',
      'dark_mode': 'الوضع المظلم',
      'light_mode': 'الوضع المضيء',
      'change_password': 'تغيير الرمز السري PIN',
      'export_data': 'تصدير البيانات',
      'import_data': 'استيراد نسخة احتياطية',
      'delete_all_data': 'مسح بيانات المحفظة',
      'about': 'حول التطبيق',
      'about_text': 'المحفظة الشخصية v1.0.0\nتطبيق حديث، نظيف وسريع لإدارة محفظتك المالية محلياً مبني بـ Flutter و Isar.',
      'new_password': 'رمز PIN الجديد',
      'confirm_password': 'تأكيد رمز PIN الجديد',
      'passwords_dont_match': 'رموز PIN غير متطابقة',
      'password_changed_success': 'تم تغيير رمز PIN بنجاح',
      'delete_confirm_title': 'هل أنت متأكد؟',
      'delete_confirm_desc': 'سيتم حذف هذه العملية نهائياً.',
      'wipe_confirm_desc': 'سيتم حذف جميع العمليات، الإعدادات، وبيانات المحفظة نهائياً. هذا الإجراء لا يمكن التراجع عنه.',
      'yes': 'نعم',
      'no': 'لا',
      'export_success': 'تم تصدير التقرير بنجاح',
      'import_success': 'تمت استعادة المحفظة بنجاح',
      'import_failed': 'فشل الاستعادة: ملف غير صالح',
      'fast_entry': 'إدخال سريع',
      'shortcuts': 'مبالغ سريعة',
      'last_category': 'آخر تصنيف مستخدم',
      'sorting': 'ترتيب حسب',
      'sort_newest': 'الأحدث أولاً',
      'sort_oldest': 'الأقدم أولاً',
      'sort_highest': 'المبلغ الأعلى',
      'sort_lowest': 'المبلغ الأقل',
      'sort_category': 'التصنيف',
      'currency': 'ج.م',
      'type': 'نوع العملية',
      'deposit': 'إيداع',
      'expense': 'مصروف',
      // Advanced features keys
      'loans_debts': 'الديون والسلف',
      'money_lent': 'سلّفت حد',
      'money_borrowed': 'استلفت من حد',
      'repayment': 'سداد دفعة',
      'financial_contacts': 'جهات الاتصال المالية',
      'remaining': 'المتبقي',
      'repay_loan': 'تسجيل سداد',
      'lent_amount': 'ليا عنده',
      'borrowed_amount': 'عليا ليه',
      'due_date': 'ميعاد السداد',
      'loan_status_open': 'مفتوحة',
      'loan_status_partial': 'جزئي',
      'loan_status_paid': 'تم السداد',
      'my_debts': 'الفلوس اللي عليا',
      'my_loans': 'الفلوس اللي ليا',
      'active_loans': 'الديون النشطة',
      'archived_loans': 'الأرشيف',
      'payment_method': 'وسيلة الدفع',
      'notes': 'الملاحظات',
      'location': 'الموقع الجغرافي',
      'hide_balances': 'إخفاء الأرصدة',
      'budget_limit': 'سقف الميزانية',
      'savings_goals': 'أهداف الادخار',
      'target': 'الهدف',
      'saved': 'الموفر',
      'quick_add': 'المفضلات السريعة',
      'payment_cash': 'كاش',
      'payment_visa': 'بطاقة فيزا',
      'payment_bank': 'حساب بنكي',
      'payment_instapay': 'إنستا باي',
      'payment_vodafone': 'فودافون كاش',
      'payment_ewallet': 'محفظة إلكترونية',
      'wallet_name': 'المحفظة المستخدمة',
      'new_wallet': 'محفظة جديدة',
      'add_wallet': 'إضافة محفظة',
      'net_worth': 'صافي الثروة',
      'budgets': 'الميزانيات',
      'active_budgets': 'الميزانيات النشطة',
      'add_budget': 'تحديد سقف مالي',
      'add_goal': 'إضافة هدف ادخار',
      'largest_expense': 'أكبر مصروف',
      'largest_deposit': 'أكبر إيداع',
      'daily_avg': 'متوسط المصاريف اليومي',
      'comparison_last_month': 'مقارنة بالشهر الماضي',
      'receipt_photo': 'صورة الفاتورة المرفقة',
      'add_photo': 'إرفاق صورة',
      'no_photo': 'لا يوجد مرفقات',
      'spent_warning': 'تنبيه: لقد استهلكت 80% من ميزانيتك المحددة!',
      // Predefined Categories
      'cat_salary': 'راتب',
      'cat_investment': 'استثمار',
      'cat_gift': 'هدية',
      'cat_food': 'طعام',
      'cat_transport': 'مواصلات',
      'cat_shopping': 'تسوق',
      'cat_bills': 'فواتير',
      'cat_entertainment': 'ترفيه',
      'cat_health': 'صحة',
      'cat_education': 'تعليم',
      'cat_other': 'أخرى',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  bool get isRTL => locale.languageCode == 'ar';

  String getCategoryTranslation(String categoryKey) {
    final lowerKey = categoryKey.toLowerCase();
    switch (lowerKey) {
      case 'salary':
        return translate('cat_salary');
      case 'investment':
        return translate('cat_investment');
      case 'gift':
        return translate('cat_gift');
      case 'food':
        return translate('cat_food');
      case 'transport':
        return translate('cat_transport');
      case 'shopping':
        return translate('cat_shopping');
      case 'bills':
        return translate('cat_bills');
      case 'entertainment':
        return translate('cat_entertainment');
      case 'health':
        return translate('cat_health');
      case 'education':
        return translate('cat_education');
      case 'other':
        return translate('cat_other');
      default:
        return translate('cat_$lowerKey');
    }
  }

  static String getEnglishCategoryKey(String translatedCategory, String currentLangCode) {
    if (currentLangCode == 'en') return translatedCategory;
    
    final arabicMap = _localizedValues['ar']!;
    
    String foundKey = 'other';
    arabicMap.forEach((key, value) {
      if (key.startsWith('cat_') && value == translatedCategory) {
        foundKey = key.replaceFirst('cat_', '');
      }
    });
    return foundKey;
  }
}

final localeProvider = Provider<Locale>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  return settings.locale;
});

final l10nProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations(locale);
});
