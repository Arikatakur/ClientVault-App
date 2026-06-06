// Lightweight, dependency-free formatting helpers (no `intl` package needed).

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const Map<String, String> _currencySymbols = {
  'USD': '\$',
  'ILS': '₪',
  'EUR': '€',
  'GBP': '£',
};

/// Formats a money [amount] for display, e.g. `$1,200`, `₪4,000`, or
/// `1,200 AUD`. Rounded to a whole unit, which is plenty for overviews.
String formatMoney(double amount, String currency) {
  final whole = amount.round();
  final digits = whole.abs().toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      grouped.write(',');
    }
    grouped.write(digits[i]);
  }
  final sign = whole < 0 ? '-' : '';
  final symbol = _currencySymbols[currency];
  if (symbol != null) {
    return '$sign$symbol$grouped';
  }
  return '$sign$grouped $currency';
}

/// Formats a date as `6 Jun 2026`.
String formatDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

/// A short relative time: `just now`, `5m ago`, `3h ago`, `2d ago`, else date.
String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(time);
}
