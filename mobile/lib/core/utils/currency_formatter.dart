import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');

  /// Formats amount into VND currency string, e.g. 45000 -> "45.000đ"
  static String format(int amount) {
    return '${_formatter.format(amount)}đ';
  }

  /// Compact format for cards, e.g. 45000 -> "45k"
  static String formatCompact(int amount) {
    if (amount >= 1000000) {
      final double tr = amount / 1000000;
      return tr % 1 == 0 ? '${tr.toInt()}tr' : '${tr.toStringAsFixed(1)}tr';
    }
    if (amount >= 1000) {
      final int k = amount ~/ 1000;
      return '${k}k';
    }
    return '$amountđ';
  }

  /// Format range, e.g. (35000, 75000) -> "~35k - 75k/người"
  static String formatRange(int minPrice, int maxPrice) {
    return '~${formatCompact(minPrice)} - ${formatCompact(maxPrice)}/người';
  }
}
