import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthenticationStatus { unknown, authenticated, unauthenticated }

class AuthenticationRepository {
  final _controller = StreamController<AuthenticationStatus>.broadcast();

  Stream<AuthenticationStatus> get status async* {
    // Begin with unknown state and then check if we have a token
    yield AuthenticationStatus.unknown;
    await Future<void>.delayed(const Duration(seconds: 1));

    final token = await _getToken();
    if (token != null) {
      yield AuthenticationStatus.authenticated;
    } else {
      yield AuthenticationStatus.unauthenticated;
    }

    // Then yield any status changes from the controller
    yield* _controller.stream;
  }

  Future<void> logIn({
    required String username,
    required String password,
  }) async {
    // In a real app, replace with actual API call
    try {
      await Future.delayed(const Duration(milliseconds: 300), () {
        if (username == 'admin' && password == 'password') {
          _saveToken('fake-jwt-token');
          _controller.add(AuthenticationStatus.authenticated);
        } else {
          throw Exception('Invalid credentials');
        }
      });
    } catch (e) {
      _controller.add(AuthenticationStatus.unauthenticated);
      rethrow;
    }
  }

  Future<void> logOut() async {
    _controller.add(AuthenticationStatus.unauthenticated);
    await _deleteToken();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  void dispose() => _controller.close();
}
