enum Role {
  reader(1),
  librarian(2),
  admin(3);

  final int level;
  const Role(this.level);
}

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final Role role;
  final int? readerId;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.readerId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: switch (json['role']) {
        'admin' => Role.admin,
        'librarian' => Role.librarian,
        _ => Role.reader,
      },
      readerId: json['readerId'] as int?,
    );
  }
}