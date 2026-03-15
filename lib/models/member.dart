class Member {
  final int? id;
  final String name;
  final String? phone;
  final DateTime joinDate;
  final DateTime expireDate;
  final String status;
  final DateTime createdAt;

  Member({
    this.id,
    required this.name,
    this.phone,
    required this.joinDate,
    required this.expireDate,
    this.status = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'join_date': joinDate.toIso8601String(),
      'expire_date': expireDate.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      joinDate: DateTime.parse(map['join_date'] as String),
      expireDate: DateTime.parse(map['expire_date'] as String),
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  int get daysRemaining {
    final now = DateTime.now();
    final difference = expireDate.difference(now);
    return difference.inDays;
  }

  bool get isExpired {
    return daysRemaining < 0;
  }

  bool get isExpiringSoon {
    return daysRemaining >= 0 && daysRemaining <= 3;
  }

  Member copyWith({
    int? id,
    String? name,
    String? phone,
    DateTime? joinDate,
    DateTime? expireDate,
    String? status,
    DateTime? createdAt,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      joinDate: joinDate ?? this.joinDate,
      expireDate: expireDate ?? this.expireDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
