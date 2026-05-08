class SavingsGoalModel {
  final int? id;
  final int userId;
  final String title;
  final String emoji;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;
  final int color;
  final DateTime createdAt;

  SavingsGoalModel({
    this.id,
    required this.userId,
    required this.title,
    this.emoji = '🎯',
    required this.targetAmount,
    this.savedAmount = 0.0,
    required this.deadline,
    this.color = 0xFF7C3AED,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress => targetAmount > 0
      ? (savedAmount / targetAmount).clamp(0.0, 1.0)
      : 0.0;

  bool get isCompleted => savedAmount >= targetAmount;

  double get remaining => (targetAmount - savedAmount).clamp(0.0, double.infinity);

  int get daysLeft => deadline.difference(DateTime.now()).inDays;

  double get dailySavingsNeeded {
    if (daysLeft <= 0 || isCompleted) return 0;
    return remaining / daysLeft;
  }

  String get badge {
    if (isCompleted) return '🏆';
    if (progress >= 0.75) return '🥇';
    if (progress >= 0.50) return '🥈';
    if (progress >= 0.25) return '🥉';
    if (progress > 0) return '⭐';
    return '🎯';
  }

  String get level {
    if (isCompleted) return 'Champion';
    if (progress >= 0.75) return 'Gold Saver';
    if (progress >= 0.50) return 'Silver Saver';
    if (progress >= 0.25) return 'Bronze Saver';
    if (progress > 0) return 'Starter';
    return 'New Goal';
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'emoji': emoji,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'deadline': deadline.toIso8601String(),
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      emoji: (map['emoji'] as String?) ?? '🎯',
      targetAmount: (map['target_amount'] as num).toDouble(),
      savedAmount: (map['saved_amount'] as num?)?.toDouble() ?? 0.0,
      deadline: DateTime.parse(map['deadline'] as String),
      color: (map['color'] as int?) ?? 0xFF7C3AED,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SavingsGoalModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? emoji,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    int? color,
    DateTime? createdAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
