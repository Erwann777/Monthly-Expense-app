class ExpenseModel {
  final int? id;
  final int userId;
  final String title;
  final double amount;
  final String category;
  final String type; // 'expense' or 'income'
  final String? note;
  final DateTime date;
  final int? walletId;
  final String? receiptPath;
  final bool isHidden;
  final int? recurringId;
  final int? splitGroupId;
  final DateTime createdAt;

  ExpenseModel({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    this.type = 'expense',
    this.note,
    required this.date,
    this.walletId,
    this.receiptPath,
    this.isHidden = false,
    this.recurringId,
    this.splitGroupId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type,
      'note': note,
      'date': date.toIso8601String(),
      'wallet_id': walletId,
      'receipt_path': receiptPath,
      'is_hidden': isHidden ? 1 : 0,
      'recurring_id': recurringId,
      'split_group_id': splitGroupId,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      type: (map['type'] as String?) ?? 'expense',
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      walletId: map['wallet_id'] as int?,
      receiptPath: map['receipt_path'] as String?,
      isHidden: (map['is_hidden'] as int?) == 1,
      recurringId: map['recurring_id'] as int?,
      splitGroupId: map['split_group_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ExpenseModel copyWith({
    int? id,
    int? userId,
    String? title,
    double? amount,
    String? category,
    String? type,
    String? note,
    DateTime? date,
    int? walletId,
    String? receiptPath,
    bool? isHidden,
    int? recurringId,
    int? splitGroupId,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
      walletId: walletId ?? this.walletId,
      receiptPath: receiptPath ?? this.receiptPath,
      isHidden: isHidden ?? this.isHidden,
      recurringId: recurringId ?? this.recurringId,
      splitGroupId: splitGroupId ?? this.splitGroupId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
