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

  // Convert Driver object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'is_active': isActive,
    };
  }

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