import 'package:intl/intl.dart';
import '../models/currency_model.dart';

class Formatters {
  static String currency(double amount, String currencyCode) {
    final curr = AppCurrencies.getByCode(currencyCode);
    final formatter = NumberFormat('#,##0.00');
    return '${curr.symbol}${formatter.format(amount)}';
  }

  static String currencyCompact(double amount, String currencyCode) {
    final curr = AppCurrencies.getByCode(currencyCode);
    if (amount >= 1000000) {
      return '${curr.symbol}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${curr.symbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '${curr.symbol}${amount.toStringAsFixed(2)}';
  }

  static String date(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String dateShort(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String monthShort(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  static String time(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String dateRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff} days ago';
    return DateFormat('MMM dd').format(date);
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
