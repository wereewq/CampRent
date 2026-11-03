class Accessory {
  final int id;
  final int categoryId;
  final String name;
  final double dailyPrice;
  final int inStock;

  const Accessory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.dailyPrice,
    required this.inStock,
  });

  factory Accessory.fromJson(Map<String, dynamic> json) => Accessory(
    id: json['id'] as int? ?? 0,
    categoryId: json['categoryId'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    dailyPrice: (json['dailyPrice'] as num?)?.toDouble() ?? 0.0,
    inStock: json['inStock'] as int? ?? 0,
  );
}
