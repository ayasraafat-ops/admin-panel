class Registration {
  final int id;
  final String email;
  final String password;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  Registration({
    required this.id,
    required this.email,
    required this.password,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
    };
  }
}