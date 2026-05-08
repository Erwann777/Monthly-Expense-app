class WalletModel {
  final int? id;
  final int userId;
  final String name;
  final String type; // 'cash', 'bank', 'e-wallet'
  final String currency;
  final double balance;
  final String icon;
  final int color;
  final DateTime createdAt;

  WalletModel({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.currency,
    this.balance = 0.0,
    this.icon = '💰',
    this.color = 0xFF7C3AED,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'name': name,
      'type': type,
      'currency': currency,
      'balance': balance,
      'icon': icon,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      currency: map['currency'] as String,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      icon: (map['icon'] as String?) ?? '💰',
      color: (map['color'] as int?) ?? 0xFF7C3AED,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  WalletModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? type,
    String? currency,
    double? balance,
    String? icon,
    int? color,
    DateTime? createdAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<Map<String, dynamic>> walletTypes = [
    {'type': 'cash', 'label': 'Cash', 'icon': '💵', 'color': 0xFF10B981},
    {'type': 'bank', 'label': 'Bank Account', 'icon': '🏦', 'color': 0xFF3B82F6},
    {'type': 'e-wallet', 'label': 'E-Wallet', 'icon': '📱', 'color': 0xFF8B5CF6},
    {'type': 'credit', 'label': 'Credit Card', 'icon': '💳', 'color': 0xFFEF4444},
    {'type': 'savings', 'label': 'Savings', 'icon': '🐷', 'color': 0xFFF59E0B},
  ];
}
