class InspectionAct {
  final int id;
  final int orderId;
  final String inspectorName;
  final String inspectionDate;
  final String conditionStatus;
  final double penaltyAmount;
  final String notes;

  const InspectionAct({
    required this.id,
    required this.orderId,
    required this.inspectorName,
    required this.inspectionDate,
    required this.conditionStatus,
    required this.penaltyAmount,
    required this.notes,
  });

  factory InspectionAct.fromJson(Map<String, dynamic> json) => InspectionAct(
    id: json['id'] as int? ?? 0,
    orderId: json['orderId'] as int? ?? 0,
    inspectorName: json['inspectorName'] as String? ?? '',
    inspectionDate: json['inspectionDate'] as String? ?? '',
    conditionStatus: json['conditionStatus'] as String? ?? 'clean',
    penaltyAmount: (json['penaltyAmount'] as num?)?.toDouble() ?? 0.0,
    notes: json['notes'] as String? ?? '',
  );
}
