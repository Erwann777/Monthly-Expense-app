class RecurringExpenseModel {
  final int? id;
  final int userId;
  final String title;
  final double amount;
  final String category;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final int? walletId;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastTriggered;
  final bool isActive;
  final DateTime createdAt;

  RecurringExpenseModel({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.frequency,
    this.walletId,
    required this.startDate,
    this.endDate,
    this.lastTriggered,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'frequency': frequency,
      'wallet_id': walletId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'last_triggered': lastTriggered?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory RecurringExpenseModel.fromMap(Map<String, dynamic> map) {
    return RecurringExpenseModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      frequency: map['frequency'] as String,
      walletId: map['wallet_id'] as int?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      lastTriggered: map['last_triggered'] != null
          ? DateTime.parse(map['last_triggered'] as String)
          : null,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  RecurringExpenseModel copyWith({
    int? id,
    int? userId,
    String? title,
    double? amount,
    String? category,
    String? frequency,
    int? walletId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastTriggered,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RecurringExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      walletId: walletId ?? this.walletId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  DateTime get nextDueDate {
    final base = lastTriggered ?? startDate;
    switch (frequency) {
      case 'daily':
        return base.add(const Duration(days: 1));
      case 'weekly':
        return base.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(base.year, base.month + 1, base.day);
      case 'yearly':
        return DateTime(base.year + 1, base.month, base.day);
      default:
        return base.add(const Duration(days: 30));
    }
  }

  bool get isDue => DateTime.now().isAfter(nextDueDate);

  static const frequencies = [
    {'key': 'daily', 'label': 'Daily', 'icon': '📅'},
    {'key': 'weekly', 'label': 'Weekly', 'icon': '📆'},
    {'key': 'monthly', 'label': 'Monthly', 'icon': '🗓️'},
    {'key': 'yearly', 'label': 'Yearly', 'icon': '🎯'},
  ];
}
