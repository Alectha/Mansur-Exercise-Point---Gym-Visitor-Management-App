class Transaction {
  final int? id;
  final String name;
  final String transactionType; // 'daily' or 'monthly'
  final int price;
  final DateTime checkInTime;
  final int? memberId;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.name,
    required this.transactionType,
    required this.price,
    required this.checkInTime,
    this.memberId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'transaction_type': transactionType,
      'price': price,
      'check_in_time': checkInTime.toIso8601String(),
      'member_id': memberId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      name: map['name'] as String,
      transactionType: map['transaction_type'] as String,
      price: map['price'] as int,
      checkInTime: DateTime.parse(map['check_in_time'] as String),
      memberId: map['member_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get typeLabel {
    switch (transactionType) {
      case 'per_sesi':
        return 'Per Sesi (Harian)';
      case 'trainer':
        return 'Trainer';
      case 'program':
        return 'Program Latihan';
      case 'therapy':
        return 'Terapi';
      case 'daily':
        return 'Harian';
      case 'monthly':
        return 'Member';
      default:
        return transactionType;
    }
  }

  Transaction copyWith({
    int? id,
    String? name,
    String? transactionType,
    int? price,
    DateTime? checkInTime,
    int? memberId,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      name: name ?? this.name,
      transactionType: transactionType ?? this.transactionType,
      price: price ?? this.price,
      checkInTime: checkInTime ?? this.checkInTime,
      memberId: memberId ?? this.memberId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
