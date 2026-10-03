class User {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final List<String> roles;
  final bool emailVerified;
  final bool mustChangePassword;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.roles,
    this.emailVerified = false,
    this.mustChangePassword = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((r) => r.toString())
              .toList() ??
          [],
      emailVerified: json['emailVerified'] as bool? ?? false,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'roles': roles,
      'emailVerified': emailVerified,
      'mustChangePassword': mustChangePassword,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
