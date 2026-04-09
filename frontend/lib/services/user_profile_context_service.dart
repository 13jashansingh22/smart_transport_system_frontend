import 'package:shared_preferences/shared_preferences.dart';

class UserProfileContext {
  const UserProfileContext({
    required this.role,
    required this.state,
    required this.city,
    required this.town,
    required this.email,
  });

  final String role;
  final String state;
  final String city;
  final String town;
  final String email;
}

class UserProfileContextService {
  static const String _roleKey = 'profile_role';
  static const String _stateKey = 'profile_state';
  static const String _cityKey = 'profile_city';
  static const String _townKey = 'profile_town';
  static const String _emailKey = 'profile_email';

  static Future<void> save({
    required String role,
    required String state,
    required String city,
    required String town,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
    await prefs.setString(_stateKey, state);
    await prefs.setString(_cityKey, city);
    await prefs.setString(_townKey, town);
    await prefs.setString(_emailKey, email);
  }

  static Future<UserProfileContext?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_roleKey);
    final state = prefs.getString(_stateKey);
    final city = prefs.getString(_cityKey);
    final town = prefs.getString(_townKey);
    final email = prefs.getString(_emailKey);

    if (role == null || state == null || city == null || town == null) {
      return null;
    }

    return UserProfileContext(
      role: role,
      state: state,
      city: city,
      town: town,
      email: email ?? '',
    );
  }
}
