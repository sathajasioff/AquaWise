class User {
  final String username;
  final String email;
  final String? persona; // optional now

  User({
    required this.username,
    required this.email,
    this.persona,
  });

  factory User.fromMap(Map<String, dynamic> data, String id) {
    return User(
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      persona: data['persona'],
    );
  }

  get name => null;

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      if (persona != null) 'persona': persona,
    };
  }
}
