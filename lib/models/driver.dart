class Driver {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phoneNumber;
  final bool isActive;

  Driver({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.isActive,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      isActive: json['is_active'],
    );
  }
}