class RentalCalculationResult {
  final int days;
  final double baseCost;
  final int discountPercent;
  final double discountedCost;
  final double accessoriesCost;
  final double deposit;
  final double total;

  const RentalCalculationResult({
    required this.days,
    required this.baseCost,
    required this.discountPercent,
    required this.discountedCost,
    required this.accessoriesCost,
    required this.deposit,
    required this.total,
  });
}

class RentalCalculator {
  static RentalCalculationResult calculate({
    required DateTime start,
    required DateTime end,
    required double dailyRate,
    required double deposit,
    double accessoriesDailyTotal = 0.0,
  }) {
    final diff = end.difference(start).inDays;
    final days = diff <= 0 ? 1 : diff;
    final baseCost = days * dailyRate;
    final discountPercent = days >= 3 ? 10 : 0;
    final discountedCost = baseCost * (1 - discountPercent / 100);
    final accessoriesCost = accessoriesDailyTotal * days;
    final total = discountedCost + accessoriesCost + deposit;

    return RentalCalculationResult(
      days: days,
      baseCost: baseCost,
      discountPercent: discountPercent,
      discountedCost: discountedCost,
      accessoriesCost: accessoriesCost,
      deposit: deposit,
      total: total,
    );
  }

  static bool checkOverlap({
    required DateTime newStart,
    required DateTime newEnd,
    required DateTime existingStart,
    required DateTime existingEnd,
  }) {
    return newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart);
  }
}
