// Number formatting shared across the app (no intl dependency).

/// Adds thousands separators: 1284560.5 → "1,284,560.50" with [decimals] 2.
String groupedNumber(double value, {int decimals = 0}) {
  final fixed = value.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final sign = value < 0 ? '-' : '';
  return parts.length > 1 ? '$sign$whole.${parts[1]}' : '$sign$whole';
}

/// Course price in whole ringgit, or "Free" for zero.
String coursePrice(double price) =>
    price <= 0 ? 'Free' : 'RM ${groupedNumber(price.roundToDouble())}';

/// Star rating to one decimal, or "New" when nobody has rated yet.
String ratingLabel(double rating) =>
    rating <= 0 ? 'New' : rating.toStringAsFixed(1);

/// "1 module", "5 modules".
String plural(int count, String one, [String? many]) =>
    '${groupedNumber(count.toDouble())} ${count == 1 ? one : (many ?? '${one}s')}';
