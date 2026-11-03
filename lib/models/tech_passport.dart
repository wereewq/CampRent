class TechPassport {
  final int id;
  final int equipmentId;
  final String serialNumber;
  final String purchaseDate;
  final int maxLoadKg;
  final int wearPercent;

  const TechPassport({
    required this.id,
    required this.equipmentId,
    required this.serialNumber,
    required this.purchaseDate,
    required this.maxLoadKg,
    required this.wearPercent,
  });

  factory TechPassport.fromJson(Map<String, dynamic> json) => TechPassport(
    id: json['id'] as int? ?? 0,
    equipmentId: json['equipmentId'] as int? ?? 0,
    serialNumber: json['serialNumber'] as String? ?? '',
    purchaseDate: json['purchaseDate'] as String? ?? '',
    maxLoadKg: json['maxLoadKg'] as int? ?? 0,
    wearPercent: json['wearPercent'] as int? ?? 0,
  );
}
