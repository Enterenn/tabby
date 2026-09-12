import 'package:equatable/equatable.dart';
import 'user.dart';

class BalanceEntry extends Equatable {
  const BalanceEntry({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
  });

  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final double amount;

  factory BalanceEntry.fromJson(Map<String, dynamic> json) => BalanceEntry(
        fromUserId: json['from_user_id'] as String,
        fromUserName: json['from_user_name'] as String,
        toUserId: json['to_user_id'] as String,
        toUserName: json['to_user_name'] as String,
        amount: (json['amount'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [fromUserId, toUserId, amount];
}

class GroupMember extends Equatable {
  const GroupMember({required this.user, required this.joinedAt});

  final User user;
  final DateTime joinedAt;

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        joinedAt: DateTime.parse(json['joined_at'] as String),
      );

  @override
  List<Object?> get props => [user, joinedAt];
}

class Group extends Equatable {
  const Group({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.members,
    required this.balance,
    this.isPinned = false,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<GroupMember> members;
  /// Solde de l'utilisateur courant dans ce groupe.
  /// Positif = on lui doit. Négatif = il doit.
  final double balance;
  /// Pin de l'utilisateur courant — indépendant des autres membres.
  final bool isPinned;

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        members: (json['members'] as List)
            .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        balance: (json['balance'] as num).toDouble(),
        isPinned: json['is_pinned'] as bool? ?? false,
      );

  Group copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<GroupMember>? members,
    double? balance,
    bool? isPinned,
  }) =>
      Group(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        members: members ?? this.members,
        balance: balance ?? this.balance,
        isPinned: isPinned ?? this.isPinned,
      );

  @override
  List<Object?> get props => [id, name, createdAt, members, balance, isPinned];
}
