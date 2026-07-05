import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_analyser/features/analytics/domain/entities/session.dart';
import 'package:flutter_background_analyser/features/analytics/domain/repositories/session_repository.dart';

class PreferencesSessionRepository implements SessionRepository {
  static const String _sessionKey = 'analytics_current_session';

  @override
  Future<void> saveSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  @override
  Future<Session?> getCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_sessionKey);
    if (jsonStr == null) return null;
    try {
      return Session.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateSession(Session session) async {
    await saveSession(session);
  }

  @override
  Future<void> endSession(String sessionId) async {
    final current = await getCurrentSession();
    if (current != null && current.sessionId == sessionId) {
      final updated = current.copyWith(
        isActive: false,
        endedAt: DateTime.now().toUtc(),
      );
      await saveSession(updated);
    }
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
