import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();

  String _activeProfileId = AppConfig.defaultProfileId;
  String _activeProfileName = AppConfig.defaultProfileName;
  Map<String, String> _availableProfiles = {};

  Map<String, dynamic>? _currentUser;
  String? _authToken;
  bool _isGuest = false;
  bool _isLoading = true;

  String get activeProfileId => _activeProfileId;
  String get activeProfileName => _activeProfileName;
  Map<String, String> get availableProfiles => _availableProfiles;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isAdmin {
    if (_currentUser == null) return false;
    final roles = _currentUser!['roles'];
    if (roles is List) {
      return roles.contains('admin') || roles.contains('commissioner');
    }
    return _currentUser!['role'] == 'admin';
  }
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null && !_isGuest;
  bool get isGuest => _isGuest;

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadPreferences();
    await fetchLiveProfiles();
  }

  /// Load cached preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPid = prefs.getString('active_profile_id');
      final savedPname = prefs.getString('active_profile_name');
      final savedToken = prefs.getString('auth_token');
      final savedUser = prefs.getString('user_session');

      if (savedPid != null && savedPid.isNotEmpty) {
        _activeProfileId = savedPid;
        _activeProfileName = savedPname ?? 'Active League';
      }

      if (savedToken != null && savedToken.isNotEmpty) {
        _authToken = savedToken;
        ApiService.authToken = savedToken;
      }

      if (savedUser != null) {
        _currentUser = jsonDecode(savedUser);
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Dynamically load all League Profiles directly from the live API
  Future<void> fetchLiveProfiles() async {
    try {
      final list = await _api.getProfiles();
      if (list.isNotEmpty) {
        final Map<String, String> map = {};
        for (final item in list) {
          final id = item['id']?.toString() ?? '';
          final name = item['name']?.toString() ?? item['display_name']?.toString() ?? id;
          if (id.isNotEmpty) {
            map[id] = name;
          }
        }

        if (map.isNotEmpty) {
          _availableProfiles = map;
          if (!_availableProfiles.containsKey(_activeProfileId)) {
            _activeProfileId = _availableProfiles.keys.first;
            _activeProfileName = _availableProfiles.values.first;
          } else {
            _activeProfileName = _availableProfiles[_activeProfileId] ?? _activeProfileName;
          }
        }
      }
    } catch (e) {
      print('Error fetching live profiles: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Switch the active fantasy league profile dynamically
  Future<void> switchProfile(String newProfileId) async {
    _activeProfileId = newProfileId;
    _activeProfileName = _availableProfiles[newProfileId] ?? 'League $newProfileId';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_profile_id', _activeProfileId);
    await prefs.setString('active_profile_name', _activeProfileName);
    notifyListeners();
  }

  /// Sign In with real backend API
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _api.login(email, password);
    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      final token = data['session']?['access_token']?.toString() ?? '';

      _currentUser = user;
      _authToken = token;
      _isGuest = false;
      ApiService.authToken = token;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_session', jsonEncode(user));
      notifyListeners();
      return {'success': true};
    } else {
      return {'success': false, 'error': res['error'] ?? 'Login failed'};
    }
  }

  /// Sign Up with real backend API
  Future<Map<String, dynamic>> signup(String email, String password, String displayName) async {
    final res = await _api.signup(email, password, displayName);
    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      final token = data['session']?['access_token']?.toString() ?? '';

      _currentUser = user;
      _authToken = token;
      _isGuest = false;
      ApiService.authToken = token;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_session', jsonEncode(user));
      notifyListeners();
      return {'success': true};
    } else {
      return {'success': false, 'error': res['error'] ?? 'Registration failed'};
    }
  }

  /// Continue as Guest without logging in
  void continueAsGuest() {
    _isGuest = true;
    notifyListeners();
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    _authToken = null;
    _isGuest = false;
    ApiService.authToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_session');
    notifyListeners();
  }
}
