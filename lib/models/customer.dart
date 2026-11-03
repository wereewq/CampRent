class Customer {
  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String passportNumber;

  const Customer({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.passportNumber,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as int? ?? 0,
    fullName: json['fullName'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    passportNumber: json['passportNumber'] as String? ?? '',
  );
}
