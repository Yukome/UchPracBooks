class LibraryCard {
  final int id;
  final String number;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const LibraryCard({
    required this.id,
    required this.number,
    required this.issuedAt,
    required this.expiresAt,
  });

  LibraryCard copyWith({
    String? number,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) {
    return LibraryCard(
      id: id,
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory LibraryCard.fromJson(Map<String, dynamic> json) => LibraryCard(
    id: json['id'] as int? ?? 0,
    number: json['number'] as String? ?? '',
    issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '') ?? DateTime.now(),
    expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class Reader {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final LibraryCard? card;
  final DateTime? deletedAt;

  const Reader({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Reader copyWith({
    String? fullName,
    String? email,
    String? phone,
    LibraryCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Reader(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'card': card?.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Reader.fromJson(Map<String, dynamic> json) => Reader(
    id: json['id'] as int? ?? 0,
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    card: json['card'] != null ? LibraryCard.fromJson(json['card'] as Map<String, dynamic>) : null,
    deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
  );
}