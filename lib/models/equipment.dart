class Equipment {
  final int id;
  final int categoryId;
  final String name;
  final String brand;
  final double dailyPrice;
  final double deposit;
  final String status;

  const Equipment({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.brand,
    required this.dailyPrice,
    required this.deposit,
    required this.status,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
    id: json['id'] as int? ?? 0,
    categoryId: json['categoryId'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    dailyPrice: (json['dailyPrice'] as num?)?.toDouble() ?? 0.0,
    deposit: (json['deposit'] as num?)?.toDouble() ?? 0.0,
    status: json['status'] as String? ?? 'available',
  );
}
