class User {
  final String username;
  final String email;
  final String? userType; // optional now

  User({
    required this.username,
    required this.email,
    this.userType,
  });

  factory User.fromMap(Map<String, dynamic> data, String id) {
    return User(
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      userType: data['userType'],
    );
  }

  get name => null;

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      if (userType != null) 'userType': userType,
    };
  }
}
