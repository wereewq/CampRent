class RentalOrder {
  final int id;
  final int customerId;
  final int equipmentId;
  final String startDate;
  final String endDate;
  final int totalDays;
  final double dailyRate;
  final double baseCost;
  final int discountPercent;
  final double depositAmount;
  final double totalAmount;
  final String status;

  const RentalOrder({
    required this.id,
    required this.customerId,
    required this.equipmentId,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.dailyRate,
    required this.baseCost,
    required this.discountPercent,
    required this.depositAmount,
    required this.totalAmount,
    required this.status,
  });

  factory RentalOrder.fromJson(Map<String, dynamic> json) => RentalOrder(
    id: json['id'] as int? ?? 0,
    customerId: json['customerId'] as int? ?? 0,
    equipmentId: json['equipmentId'] as int? ?? 0,
    startDate: json['startDate'] as String? ?? '',
    endDate: json['endDate'] as String? ?? '',
    totalDays: json['totalDays'] as int? ?? 1,
    dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
    baseCost: (json['baseCost'] as num?)?.toDouble() ?? 0.0,
    discountPercent: json['discountPercent'] as int? ?? 0,
    depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    status: json['status'] as String? ?? 'active',
  );
}
