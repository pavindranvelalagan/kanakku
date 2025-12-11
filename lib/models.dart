enum TransactionType { paid, borrowed, partial, autoSubscription }

class Friend {
  Friend({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  Friend copyWith({String? name}) {
    return Friend(id: id, name: name ?? this.name, createdAt: createdAt);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static Friend fromMap(Map<dynamic, dynamic> map) {
    return Friend(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
    );
  }
}

class LedgerTransaction {
  LedgerTransaction({
    required this.id,
    required this.friendId,
    required this.amount,
    required this.delta,
    required this.type,
    required this.description,
    required this.date,
    required this.createdAt,
    this.subscriptionId,
    this.monthStamp,
  });

  final String id;
  final String friendId;
  final int amount; // Rupees as integer
  final int delta; // Signed impact on "what you are owed"
  final TransactionType type;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final String? subscriptionId;
  final String? monthStamp;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'friendId': friendId,
      'amount': amount,
      'delta': delta,
      'type': type.name,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'subscriptionId': subscriptionId,
      'monthStamp': monthStamp,
    };
  }

  static LedgerTransaction fromMap(Map<dynamic, dynamic> map) {
    final typeName = map['type'] as String? ?? TransactionType.paid.name;
    final parsedType =
        TransactionType.values.firstWhere((t) => t.name == typeName);
    return LedgerTransaction(
      id: map['id'] as String,
      friendId: map['friendId'] as String,
      amount: map['amount'] as int? ?? 0,
      delta: map['delta'] as int? ?? 0,
      type: parsedType,
      description: map['description'] as String? ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int? ?? 0),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
      subscriptionId: map['subscriptionId'] as String?,
      monthStamp: map['monthStamp'] as String?,
    );
  }
}

class SubscriptionPlan {
  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.amountPerMember,
    required this.memberIds,
    required this.createdAt,
    required this.lastBilledMonth,
  });

  final String id;
  final String name;
  final int amountPerMember;
  final List<String> memberIds;
  final DateTime createdAt;
  final String lastBilledMonth; // yyyy-MM

  SubscriptionPlan copyWith({
    String? name,
    int? amountPerMember,
    List<String>? memberIds,
    String? lastBilledMonth,
  }) {
    return SubscriptionPlan(
      id: id,
      name: name ?? this.name,
      amountPerMember: amountPerMember ?? this.amountPerMember,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt,
      lastBilledMonth: lastBilledMonth ?? this.lastBilledMonth,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amountPerMember': amountPerMember,
      'memberIds': memberIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastBilledMonth': lastBilledMonth,
    };
  }

  static SubscriptionPlan fromMap(Map<dynamic, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      amountPerMember: map['amountPerMember'] as int? ?? 0,
      memberIds:
          (map['memberIds'] as List?)?.map((e) => e as String).toList() ?? [],
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
      lastBilledMonth: map['lastBilledMonth'] as String? ?? '',
    );
  }
}

class AppSettings {
  AppSettings({required this.userName, required this.themeMode});

  final String userName;
  final String themeMode; // system|light|dark

  AppSettings copyWith({String? userName, String? themeMode}) {
    return AppSettings(
      userName: userName ?? this.userName,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toMap() =>
      {'userName': userName, 'themeMode': themeMode};

  static AppSettings fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return AppSettings(userName: '', themeMode: 'system');
    }
    return AppSettings(
      userName: map['userName'] as String? ?? '',
      themeMode: map['themeMode'] as String? ?? 'system',
    );
  }
}

String formatSignedAmount(int amount) {
  final prefix = amount >= 0 ? '+' : '-';
  final value = amount.abs();
  return '$prefix Rs $value';
}

String formatDateShort(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final month = months[date.month - 1];
  return '$month ${date.day.toString().padLeft(2, '0')}';
}

String monthLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String labelForType(TransactionType type) {
  switch (type) {
    case TransactionType.paid:
      return 'I Paid';
    case TransactionType.borrowed:
      return 'I Borrowed';
    case TransactionType.partial:
      return 'Partial Payment';
    case TransactionType.autoSubscription:
      return 'Auto Subscription';
  }
}
