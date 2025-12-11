import '../models.dart';

/// Formats an amount with a leading sign and a plain `Rs` prefix.
String formatSignedAmount(int amount) {
  final prefix = amount >= 0 ? '+' : '-';
  final value = amount.abs();
  return '$prefix Rs $value';
}

/// Short month/day label, e.g. `Jan 05`.
String formatDateShort(DateTime date) {
  const months = [
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
    'Dec'
  ];
  final month = months[date.month - 1];
  return '$month ${date.day.toString().padLeft(2, '0')}';
}

/// Month/year label, e.g. `Jan 2025`.
String monthLabel(DateTime date) {
  const months = [
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
    'Dec'
  ];
  return '${months[date.month - 1]} ${date.year}';
}

/// Human readable description for the transaction type.
String labelForType(TransactionType type) {
  switch (type) {
    case TransactionType.paid:
      return 'I Paid';
    case TransactionType.borrowed:
      return 'I Borrowed';
    case TransactionType.partial:
      return 'Partial Payment';
    case TransactionType.autoSubscription:
      return 'Auto Subscription';
  }
}
