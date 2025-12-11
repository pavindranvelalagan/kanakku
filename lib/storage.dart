import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

class LedgerRepository {
  LedgerRepository._(
    this._friends,
    this._transactions,
    this._subscriptions,
    this._settings,
  );

  final Box _friends;
  final Box _transactions;
  final Box _subscriptions;
  final Box _settings;
  final Uuid _uuid = const Uuid();

  static Future<LedgerRepository> bootstrap() async {
    await Hive.initFlutter();
    final friendsBox = await Hive.openBox('friends');
    final transactionsBox = await Hive.openBox('transactions');
    final subscriptionsBox = await Hive.openBox('subscriptions');
    final settingsBox = await Hive.openBox('settings');
    return LedgerRepository._(
      friendsBox,
      transactionsBox,
      subscriptionsBox,
      settingsBox,
    );
  }

  List<Friend> loadFriends() {
    return _friends.values
        .map((e) => Friend.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<LedgerTransaction> loadTransactions() {
    return _transactions.values
        .map((e) => LedgerTransaction.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<SubscriptionPlan> loadSubscriptions() {
    return _subscriptions.values
        .map((e) => SubscriptionPlan.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<String> addFriend(String name) async {
    final id = _uuid.v4();
    final friend = Friend(id: id, name: name.trim(), createdAt: DateTime.now());
    await _friends.put(id, friend.toMap());
    return id;
  }

  Future<void> addTransaction(LedgerTransaction tx) async {
    await _transactions.put(tx.id, tx.toMap());
  }

  Future<void> addSubscription(SubscriptionPlan plan) async {
    await _subscriptions.put(plan.id, plan.toMap());
  }

  Future<void> updateSubscription(SubscriptionPlan plan) async {
    await _subscriptions.put(plan.id, plan.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _transactions.delete(id);
  }

  Future<void> deleteSubscription(String id) async {
    await _subscriptions.delete(id);
    final keysToDelete = _transactions.keys.where((key) {
      final value = _transactions.get(key);
      if (value is Map) {
        return value['subscriptionId'] == id;
      }
      return false;
    }).toList();
    await _transactions.deleteAll(keysToDelete);
  }

  Future<void> deleteFriend(String id) async {
    await _friends.delete(id);
    final keysToDelete = _transactions.keys.where((key) {
      final value = _transactions.get(key);
      if (value is Map) {
        return value['friendId'] == id;
      }
      return false;
    }).toList();
    await _transactions.deleteAll(keysToDelete);
  }

  Future<void> ensureMonthlySubscriptionCharges(DateTime now) async {
    final monthStamp = _monthStamp(now);
    final existing = loadTransactions();
    for (final plan in loadSubscriptions()) {
      final alreadyBilled = plan.lastBilledMonth == monthStamp ||
          existing.any(
            (t) =>
                t.subscriptionId == plan.id && (t.monthStamp ?? '') == monthStamp,
          );
      if (alreadyBilled) continue;
      await _postSubscriptionForMonth(plan, now, monthStamp);
    }
  }

  Future<void> ensurePlanChargesForCurrentMonth(
    SubscriptionPlan plan,
    DateTime now,
  ) async {
    final monthStamp = _monthStamp(now);
    final existing = loadTransactions().any(
      (t) => t.subscriptionId == plan.id && (t.monthStamp ?? '') == monthStamp,
    );
    if (plan.lastBilledMonth == monthStamp || existing) return;
    await _postSubscriptionForMonth(plan, now, monthStamp);
  }

  Future<void> _postSubscriptionForMonth(
    SubscriptionPlan plan,
    DateTime now,
    String monthStamp,
  ) async {
    for (final member in plan.memberIds) {
      final tx = LedgerTransaction(
        id: _uuid.v4(),
        friendId: member,
        amount: plan.amountPerMember,
        delta: plan.amountPerMember,
        type: TransactionType.autoSubscription,
        description: '${plan.name} (${monthLabel(now)})',
        date: now,
        createdAt: now,
        subscriptionId: plan.id,
        monthStamp: monthStamp,
      );
      await addTransaction(tx);
    }
    await updateSubscription(plan.copyWith(lastBilledMonth: monthStamp));
  }

  static String _monthStamp(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  AppSettings loadSettings() {
    final data = _settings.get('settings');
    if (data is Map) {
      return AppSettings.fromMap(Map<dynamic, dynamic>.from(data));
    }
    return AppSettings(userName: '');
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settings.put('settings', settings.toMap());
  }
}

class LedgerController extends ChangeNotifier {
  LedgerController(this.repository) {
    _friendsListener = repository._friends.listenable();
    _txListener = repository._transactions.listenable();
    _subscriptionListener = repository._subscriptions.listenable();
    _settingsListener = repository._settings.listenable();
    _friendsListener.addListener(_refresh);
    _txListener.addListener(_refresh);
    _subscriptionListener.addListener(_refresh);
    _settingsListener.addListener(_refresh);
    _refresh();
  }

  final LedgerRepository repository;
  late final ValueListenable _friendsListener;
  late final ValueListenable _txListener;
  late final ValueListenable _subscriptionListener;
  late final ValueListenable _settingsListener;

  List<Friend> friends = [];
  List<LedgerTransaction> transactions = [];
  List<SubscriptionPlan> subscriptions = [];
  AppSettings settings = AppSettings(userName: '');

  Future<void> _refresh() async {
    friends = repository.loadFriends();
    transactions = repository.loadTransactions();
    subscriptions = repository.loadSubscriptions();
    settings = repository.loadSettings();
    notifyListeners();
  }

  int balanceForFriend(String friendId) {
    return transactions
        .where((t) => t.friendId == friendId)
        .fold<int>(0, (sum, tx) => sum + tx.delta);
  }

  int totalOwedToYou() {
    return friends
        .map((f) => balanceForFriend(f.id))
        .where((b) => b > 0)
        .fold(0, (a, b) => a + b);
  }

  int totalNetBalance() {
    return friends.fold<int>(0, (sum, f) => sum + balanceForFriend(f.id));
  }

  List<LedgerTransaction> transactionsForFriend(String friendId) {
    final filtered =
        transactions.where((t) => t.friendId == friendId).toList(growable: false);
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<void> createFriend(String name) async {
    if (name.trim().isEmpty) return;
    await repository.addFriend(name.trim());
  }

  Future<void> addTransactionForFriend({
    required String friendId,
    required TransactionType type,
    required int amount,
    required String description,
    required DateTime date,
    required int currentBalance,
  }) async {
    final now = DateTime.now();
    int delta;
    switch (type) {
      case TransactionType.paid:
        delta = amount;
        break;
      case TransactionType.borrowed:
        delta = -amount;
        break;
      case TransactionType.partial:
        delta = currentBalance >= 0 ? -amount : amount;
        break;
      case TransactionType.autoSubscription:
        delta = amount;
        break;
    }
    final tx = LedgerTransaction(
      id: const Uuid().v4(),
      friendId: friendId,
      amount: amount,
      delta: delta,
      type: type,
      description: description,
      date: date,
      createdAt: now,
    );
    await repository.addTransaction(tx);
  }

  Future<void> settleFull(String friendId) async {
    final balance = balanceForFriend(friendId);
    if (balance == 0) return;
    final now = DateTime.now();
    final delta = -balance;
    final tx = LedgerTransaction(
      id: const Uuid().v4(),
      friendId: friendId,
      amount: balance.abs(),
      delta: delta,
      type: TransactionType.partial,
      description: 'Settle up',
      date: now,
      createdAt: now,
    );
    await repository.addTransaction(tx);
  }

  Future<void> addSubscriptionPlan({
    required String name,
    required int amountPerMember,
    required List<String> memberIds,
  }) async {
    final plan = SubscriptionPlan(
      id: const Uuid().v4(),
      name: name.trim(),
      amountPerMember: amountPerMember,
      memberIds: memberIds,
      createdAt: DateTime.now(),
      lastBilledMonth: '',
    );
    await repository.addSubscription(plan);
    await repository.ensurePlanChargesForCurrentMonth(plan, DateTime.now());
  }

  Future<void> deleteTransaction(String id) async {
    await repository.deleteTransaction(id);
  }

  Future<void> deleteFriend(String id) async {
    await repository.deleteFriend(id);
  }

  Future<void> deleteSubscription(String id) async {
    await repository.deleteSubscription(id);
  }

  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    settings = settings.copyWith(userName: trimmed);
    await repository.saveSettings(settings);
    notifyListeners();
  }

  String effectiveAppTitle() {
    final name = settings.userName.trim();
    if (name.isEmpty) return 'Kanakku';
    return "$name's Kanakku";
  }

  List<LedgerTransaction> owedByYou() =>
      transactions.where((t) => t.delta < 0).toList();

  List<LedgerTransaction> owedToYou() =>
      transactions.where((t) => t.delta > 0).toList();
}
