class User {
  final int? id;
  final String email;
  final String password;
  final String role;
  final String? name;

  User({
    this.id,
    required this.email,
    required this.password,
    required this.role,
    this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'role': role,
      'name': name,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'user',
      name: map['name'],
    );
  }
}