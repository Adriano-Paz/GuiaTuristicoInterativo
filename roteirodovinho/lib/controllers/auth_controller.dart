import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  User? get usuarioAtual {
    return _authService.usuarioAtual;
  }

  Future<User?> loginComGoogle() async {
    return await _authService.loginComGoogle();
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}