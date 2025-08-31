import '../models/user.dart';

class LoginController {
  User? _user;

  bool login(String username, String password) {
    // Simple mock validation
    if (username == "admin" && password == "1234") {
      _user = User(username: username, email: "admin@example.com");
      return true;
    }
    return false;
  }

  User? get user => _user;
}
