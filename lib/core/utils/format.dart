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

/// Formats a money [amount] for display, e.g. `$1,200` (USD) or `1,200 EUR`.
/// The amount is rounded to a whole unit, which is plenty for budget overviews.
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
  if (currency == 'USD') {
    return '$sign\$$grouped';
  }
  return '$sign$grouped $currency';
}

/// Formats a date as `6 Jun 2026`.
String formatDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}
