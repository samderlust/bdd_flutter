class User {
  final String name;
  final String email;

  User({required this.name, required this.email});
}

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<User> login(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    if (email == 'test@test.com' && password == 'password') {
      return User(name: 'Test User', email: email);
    }
    throw Exception('Invalid credentials');
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
