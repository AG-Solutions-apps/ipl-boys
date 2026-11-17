import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/fpl_team.dart';
import '../models/player.dart';
import '../models/gameweek.dart';
import '../models/trade.dart';
import '../models/player_match_stat.dart';

class ApiService {
  final http.Client _client = http.Client();
  static String? authToken;

  /// Headers sent with each request
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  /// =========================================================================
  /// AUTHENTICATION APIS
  /// =========================================================================

  /// Sign In with Email & Password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final uri = Uri.parse('${AppConfig.cleanBaseUrl}/auth/login');
      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = decoded['session']?['access_token']?.toString();
        if (token != null) {
          authToken = token;
        }
        return {'success': true, 'data': decoded};
      } else {
        final msg = decoded['error'] ?? decoded['message'] ?? 'Login failed (${response.statusCode})';
        return {'success': false, 'error': msg.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  /// Sign Up / Register New User
  Future<Map<String, dynamic>> signup(String email, String password, String displayName) async {
    try {
      final uri = Uri.parse('${AppConfig.cleanBaseUrl}/auth/signup');
      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'options': {
            'data': {
              'display_name': displayName.trim(),
            }
          }
        }),
      ).timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = decoded['session']?['access_token']?.toString();
        if (token != null) {
          authToken = token;
        }
        return {'success': true, 'data': decoded};
      } else {
        final msg = decoded['error'] ?? decoded['message'] ?? 'Registration failed (${response.statusCode})';
        return {'success': false, 'error': msg.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  /// Core Dynamic GET query builder for any table
  Future<List<dynamic>> queryTable(
    String table, {
    Map<String, String>? filters,
    String? order,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (filters != null) {
        queryParams.addAll(filters);
      }
      if (order != null) {
        queryParams['order'] = order;
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final uri = Uri.parse('${AppConfig.cleanBaseUrl}/$table')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['data'] is List) return decoded['data'];
        return [decoded];
      } else {
        print('API Notice [GET $table]: status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Network Exception [GET $table]: $e');
      return [];
    }
  }

  /// Core Dynamic POST query for insert/upsert
  Future<bool> insertRecord(String table, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${AppConfig.cleanBaseUrl}/$table');
      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Network Exception [POST $table]: $e');
      return false;
    }
  }

  /// Core Dynamic PATCH query for updates
  Future<bool> updateRecord(String table, String id, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${AppConfig.cleanBaseUrl}/$table?eq[id]=$id');
      final response = await _client.patch(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Network Exception [PATCH $table]: $e');
      return false;
    }
  }

  /// =========================================================================
  /// DYNAMIC ENTITY APIS
  /// =========================================================================

  /// Fetch all Dynamic Profiles from live backend
  Future<List<Map<String, dynamic>>> getProfiles() async {
    var list = await queryTable('game_profiles');
    if (list.isEmpty) {
      list = await queryTable('profiles');
    }
    return list.cast<Map<String, dynamic>>();
  }

  /// Fetch all Dynamic IPL Teams from live backend
  Future<List<Map<String, dynamic>>> getIplTeams() async {
    final list = await queryTable('ipl_teams');
    return list.cast<Map<String, dynamic>>();
  }

  /// Fetch all IPL Players dynamically (sorted alphabetically by name)
  Future<List<Player>> getPlayers() async {
    final list = await queryTable('players', order: 'name.asc');
    return list.map((json) => Player.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Fetch Fantasy Teams scoped to active League Profile
  Future<List<FplTeam>> getFplTeams({String? profileId}) async {
    final filters = <String, String>{};
    if (profileId != null && profileId.isNotEmpty) {
      filters['profile_id'] = profileId;
    }
    final list = await queryTable('fpl_teams', filters: filters.isEmpty ? null : filters, order: 'sort_order.asc');
    return list.map((json) => FplTeam.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Fetch Single FPL Team by ID
  Future<FplTeam?> getFplTeamById(String teamId) async {
    final list = await queryTable('fpl_teams', filters: {'id': teamId}, limit: 1);
    if (list.isNotEmpty) {
      return FplTeam.fromJson(list.first as Map<String, dynamic>);
    }
    return null;
  }

  /// Fetch All Gameweeks dynamically (ordered by gameweek number)
  Future<List<Gameweek>> getGameweeks() async {
    final list = await queryTable('gameweeks', order: 'number.asc');
    return list.map((json) => Gameweek.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Fetch Trades dynamically for active profile
  Future<List<Trade>> getTrades({String? profileId}) async {
    final filters = <String, String>{};
    if (profileId != null && profileId.isNotEmpty) {
      filters['profile_id'] = profileId;
    }
    final list = await queryTable('trades', filters: filters.isEmpty ? null : filters, order: 'created_at.desc');
    return list.map((json) => Trade.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Fetch Player Match Stats dynamically
  Future<List<PlayerMatchStat>> getPlayerMatchStats({String? profileId, String? gameweekId}) async {
    final filters = <String, String>{};
    if (profileId != null && profileId.isNotEmpty) filters['profile_id'] = profileId;
    if (gameweekId != null && gameweekId.isNotEmpty) filters['gameweek_id'] = gameweekId;
    final list = await queryTable('player_match_stats', filters: filters.isEmpty ? null : filters);
    return list.map((json) => PlayerMatchStat.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Fetch Team Gameweek Scores (Leaderboard) dynamically
  Future<List<Map<String, dynamic>>> getTeamScores({String? profileId, String? gameweekId}) async {
    final filters = <String, String>{};
    if (profileId != null && profileId.isNotEmpty) filters['profile_id'] = profileId;
    if (gameweekId != null && gameweekId.isNotEmpty) filters['gameweek_id'] = gameweekId;
    final list = await queryTable('team_gw_scores', filters: filters.isEmpty ? null : filters, order: 'points.desc');
    return list.cast<Map<String, dynamic>>();
  }

  /// Fetch Commissioner Comments / League Notes dynamically
  Future<List<Map<String, dynamic>>> getCommissionComments({String? profileId}) async {
    final filters = <String, String>{};
    if (profileId != null && profileId.isNotEmpty) filters['profile_id'] = profileId;
    final list = await queryTable('commission_comments', filters: filters.isEmpty ? null : filters, order: 'created_at.desc');
    return list.cast<Map<String, dynamic>>();
  }

  /// Fetch Admin Bonuses dynamically
  Future<List<Map<String, dynamic>>> getAdminBonuses({String? profileId}) async {
    final filters = <String, String>{};
    if (profileId != null && profileId.isNotEmpty) filters['profile_id'] = profileId;
    final list = await queryTable('admin_bonuses', filters: filters.isEmpty ? null : filters);
    return list.cast<Map<String, dynamic>>();
  }

  /// Update Starting XI & Substitutes for an FPL Team
  Future<bool> saveSquadLineup({
    required String teamId,
    required List<String> startingXi,
    required List<String> substitutes,
    String? captain,
    String? viceCaptain,
  }) async {
    final payload = <String, dynamic>{
      'starting_xi': startingXi,
      'substitutes': substitutes,
    };
    if (captain != null) payload['captain'] = captain;
    if (viceCaptain != null) payload['vice_captain'] = viceCaptain;

    return await updateRecord('fpl_teams', teamId, payload);
  }

  /// Execute Trade RPC
  Future<bool> executeTrade(String tradeId) async {
    return await callRpc('execute_trade', {'trade_id': tradeId});
  }

  /// Execute Remote Procedure Call
  Future<bool> callRpc(String functionName, Map<String, dynamic> params) async {
    try {
      final uri = Uri.parse('${AppConfig.cleanBaseUrl}/rpc/$functionName');
      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode(params),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('RPC Exception [$functionName]: $e');
      return false;
    }
  }

  /// Test Connection directly to Live Backend
  Future<bool> testBackendConnection() async {
    try {
      final uri = Uri.parse('${AppConfig.cleanBaseUrl}/gameweeks?limit=1');
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
