// class User {
//   final String username;
//   final String email;
//   final String? persona;
//    // optional now

//   User({
//     required this.username,
//     required this.email,
//     this.persona,
//   });

//   factory User.fromMap(Map<String, dynamic> data, String id) {
//     return User(
//       username: data['username'] ?? '',
//       email: data['email'] ?? '',
//       persona: data['persona'],
//     );
//   }

//   get name => null;

//   Map<String, dynamic> toMap() {
//     return {
//       'username': username,
//       'email': email,
//       if (persona != null) 'persona': persona,
//     };
//   }
// }
class User {
  final String username;
  final String email;
  final String persona;
  final double monthlyBudget;

  User({
    required this.username,
    required this.email,
    this.persona = 'casual',
    this.monthlyBudget = 1000.0,
  });

  factory User.fromMap(Map<String, dynamic> data, String id) {
    return User(
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      persona: data['persona'] ?? 'casual',
      monthlyBudget: (data['monthlyBudget'] ?? 1000.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'persona': persona,
      'monthlyBudget': monthlyBudget,
    };
  }

  User copyWith({
    String? username,
    String? email,
    String? persona,
    double? monthlyBudget,
  }) {
    return User(
      username: username ?? this.username,
      email: email ?? this.email,
      persona: persona ?? this.persona,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }

  String get name => username.isNotEmpty ? username : 'User';
}