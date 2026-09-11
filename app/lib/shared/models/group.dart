import 'package:equatable/equatable.dart';
import 'user.dart';

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
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<GroupMember> members;
  /// Solde de l'utilisateur courant dans ce groupe.
  /// Positif = on lui doit. Négatif = il doit.
  final double balance;

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        members: (json['members'] as List)
            .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        balance: (json['balance'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [id, name, createdAt, members, balance];
}
