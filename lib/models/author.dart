class Author {
  final int id;
  final String fullName;
  final int? birthYear;
  final String country;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.fullName,
    this.birthYear,
    this.country = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Author copyWith({
    String? fullName,
    int? birthYear,
    String? country,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      fullName: fullName ?? this.fullName,
      birthYear: birthYear ?? this.birthYear,
      country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'birthYear': birthYear,
    'country': country,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Author.fromJson(Map<String, dynamic> json) => Author(
    id: json['id'] as int? ?? 0,
    fullName: json['fullName'] as String? ?? '',
    birthYear: json['birthYear'] as int?,
    country: json['country'] as String? ?? '',
    deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
  );
}