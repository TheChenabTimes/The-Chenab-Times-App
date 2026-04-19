import 'dart:convert';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? photo;
  final String loginType;
  final int bestStreak;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photo,
    required this.loginType,
    this.bestStreak = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] is int ? map['id'] as int : int.parse('${map['id']}'),
      name: '${map['name'] ?? ''}',
      email: '${map['email'] ?? ''}',
      photo: map['photo']?.toString(),
      loginType: '${map['login_type'] ?? map['loginType'] ?? 'email'}',
      bestStreak: map['best_streak'] is int
          ? map['best_streak'] as int
          : int.tryParse('${map['best_streak'] ?? 0}') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photo': photo,
      'login_type': loginType,
      'best_streak': bestStreak,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) {
    return UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
