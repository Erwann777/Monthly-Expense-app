class UserModel {
  final int? id;
  final String username;
  final String password;
  final String displayName;
  final String currency;
  final double monthlyBudget;
  final String? avatarEmoji;
  final String? profilePhotoPath;
  final String? pin;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.username,
    required this.password,
    required this.displayName,
    this.currency = 'USD',
    this.monthlyBudget = 1000.0,
    this.avatarEmoji,
    this.profilePhotoPath,
    this.pin,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'username': username,
      'password': password,
      'display_name': displayName,
      'currency': currency,
      'monthly_budget': monthlyBudget,
      'avatar_emoji': avatarEmoji,
      'profile_photo_path': profilePhotoPath,
      'pin': pin,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      displayName: map['display_name'] as String,
      currency: (map['currency'] as String?) ?? 'USD',
      monthlyBudget: (map['monthly_budget'] as num?)?.toDouble() ?? 1000.0,
      avatarEmoji: map['avatar_emoji'] as String?,
      profilePhotoPath: map['profile_photo_path'] as String?,
      pin: map['pin'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? password,
    String? displayName,
    String? currency,
    double? monthlyBudget,
    String? avatarEmoji,
    String? profilePhotoPath,
    String? pin,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      currency: currency ?? this.currency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      pin: pin ?? this.pin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
